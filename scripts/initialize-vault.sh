#!/bin/bash

set -euo pipefail

caDir=$1
dir=$2
caPass=$3

./applyDir.sh haproxy
./applyDir.sh vault

echo "Waiting for vault to start up"

sleep 5
kubectl wait --namespace=vault --for=condition=ready --timeout=3000s pods vault-0

export VAULT_ADDR="https://vault.cerberus-systems.de"
export VAULT_CACERT="$caDir/ca.crt"
export VAULT_CLIENT_CERT="$dir/vault-operator.crt"
export VAULT_CLIENT_KEY="$dir/vault-operator.key"

sleep 5

initResponse=$(curl --cacert "$VAULT_CACERT" --cert "$VAULT_CLIENT_CERT" --key "$VAULT_CLIENT_KEY" \
    -XPUT --data '{ "secret_shares": 5, "secret_threshold": 3 }' "$VAULT_ADDR/v1/sys/init" 2> /dev/null)

vaultKeys=$(echo "$initResponse" | jq -r '.keys | .[]')
rootToken=$(echo "$initResponse" | jq -r .root_token)

echo "Vault unseal keys:
$vaultKeys

Vault root token:
$rootToken" > vault_keys.txt

echo "Initialized vault - find keys in vault_keys.txt"

function curlCmd {
    curl --cacert "$VAULT_CACERT" --cert "$VAULT_CLIENT_CERT" \
        --key "$VAULT_CLIENT_KEY" --header "X-Vault-Token: $rootToken" "$@" 2>/dev/null
}

function unsealVault {
    for i in 1 2 3; do
        key=$(echo "$vaultKeys" | sed -n "${i}p")

        echo "{ \"key\": \"$key\" }" | \
            curlCmd -XPUT --data @- "$VAULT_ADDR/v1/sys/unseal" >/dev/null
    done
}

unsealVault

for name in pki_int_outside pki_int_inside; do
    echo "Generating and signing $name"

    curlCmd -XPOST --data '{ "type": "pki", "max_lease_ttl": "720h" }' \
        "$VAULT_ADDR/v1/sys/mounts/$name" >/dev/null

    curlCmd -XPOST --data "{ \"common_name\": \"Cerberus Systems Intermediate CA ($name)\", \"key_bits\": 4096, \"organization\": \"Cerberus Systems\" }" \
        "$VAULT_ADDR/v1/$name/intermediate/generate/internal" \
        | jq -r '.data .csr' > "$dir/$name.csr"

    echo -e "$caPass\ny\ny\n" | \
        openssl ca -config "$caDir/ca.conf" -cert "$caDir/ca.crt" -keyfile "$caDir/ca.key" \
                -extensions x509_ext -out "$dir/$name.crt" -passin stdin -in "$dir/$name.csr" -notext

    cat "$dir/$name.crt" "$caDir/ca.crt" > "$dir/$name-chain.crt"

    curlCmd -XPOST --data "{ \"certificate\": \"$(sed -z 's/\n/\\n/g' < "$dir/$name-chain.crt")\" }" \
        "$VAULT_ADDR/v1/$name/intermediate/set-signed"

    curlCmd -XPOST --data '{ "allowed_domains": ["cerberus-systems.de", "cerberus-systems.com", "svc.cluster.local"], "allow_subdomains": true, "max_ttl": "1860h" }' \
        "$VAULT_ADDR/v1/$name/roles/get-cert"
done

# Let vault generate a certificate for itself
for name in vault vault-operator; do
    echo "Generating certificate for $name"
    result=$(curlCmd -XPOST --data "{ \"common_name\": \"$name.cerberus-systems.de\", \"alt_names\": \"$name.cerberus-systems.com,$name.$name.svc.cluster.local\" }" \
        "$VAULT_ADDR/v1/pki_int_outside/issue/get-cert")

    echo "$result" | jq -r '.data.certificate' > "$dir/$name.crt"
    echo "$result" | jq -r '.data.private_key' > "$dir/$name.key"
done

echo "Copy vault cert to server"
$SSH_COMMAND "sudo tee /data/vault/ssl/vault.crt >/dev/null" < "$dir/vault.crt"
$SSH_COMMAND "sudo tee /data/vault/ssl/vault.key >/dev/null" < "$dir/vault.key"

cp "$dir/pki_int_outside-chain.crt" ca-chain.crt

echo "Restarting vault"
./applyDir.sh vault delete
./applyDir.sh vault

export VAULT_CACERT="ca-chain.crt"
sleep 5

kubectl wait --namespace=vault --for=condition=ready --timeout=3000s pods vault-0

unsealVault

echo "Creating get-cert vault policy"
policy=$(dhall text --file vault/policies/get-cert.hcl.dhall | sed -z 's/\n/\\n/g' | sed 's/"/\\"/g')
curlCmd -XPUT --data "{ \"policy\": \"$policy\" }" "$VAULT_ADDR/v1/sys/policy/get-cert"

echo "Setting up kubernetes authentication"

curlCmd -XPOST --data '{ "type": "kubernetes" }' "$VAULT_ADDR/v1/sys/auth/kubernetes"
curlCmd -XPOST --data '{ "kubernetes_host": "https://kubernetes.default.svc" }'  "$VAULT_ADDR/v1/auth/kubernetes/config"
curlCmd -XPOST --data '{ "bound_service_account_names": ["default"], "bound_service_account_namespaces": ["*"], "token_ttl": "2h", "token_policies": ["get-cert"] }' "$VAULT_ADDR/v1/auth/kubernetes/role/get-cert"

echo "Enabling key-value backend"

curlCmd -XPOST --data '{ "type": "kv", "version": "2" }' "$VAULT_ADDR/v1/sys/mounts/kv"

echo "Saving ldap admin passwords in vault"
adminPass=$(tr -dc _A-Za-z-0-9 < /dev/urandom | head -c"${1:-32}")
configPass=$(tr -dc _A-Za-z-0-9 < /dev/urandom | head -c"${1:-32}")

curlCmd -XPOST --data "{ \"data\": { \"admin\": \"$adminPass\", \"config-admin\": \"$configPass\" } }" "$VAULT_ADDR/v1/kv/data/ldap"
