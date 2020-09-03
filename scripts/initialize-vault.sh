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
        --key "$VAULT_CLIENT_KEY" --header "X-Vault-Token: $rootToken" "$@"
}

for i in 1 2 3; do
    key=$(echo "$vaultKeys" | sed -n "${i}p")

    echo "{ \"key\": \"$key\" }" | \
        curlCmd -XPUT --data @- "$VAULT_ADDR/v1/sys/unseal" >/dev/null 2>&1
done

for name in pki_int_outside pki_int_inside; do
    echo "Generating and signing $name"

    curlCmd -XPOST --data '{ "type": "pki", "max_lease_ttl": "720h" }' \
        "$VAULT_ADDR/v1/sys/mounts/$name" >/dev/null 2>&1

    curlCmd -XPOST --data "{ \"common_name\": \"Cerberus Systems Intermediate CA ($name)\", \"key_bits\": 4096, \"organization\": \"Cerberus Systems\" }" \
        "$VAULT_ADDR/v1/$name/intermediate/generate/internal" 2>/dev/null \
        | jq -r '.data .csr' > "$dir/$name.csr"

    echo -e "$caPass\ny\ny\n" | \
        openssl ca -config "$caDir/ca.conf" -cert "$caDir/ca.crt" -keyfile "$caDir/ca.key" \
                -extensions x509_ext -out "$dir/$name.crt" -passin stdin -in "$dir/$name.csr" -notext

    cat "$dir/$name.crt" "$caDir/ca.crt" > "$dir/$name-chain.crt"

    curlCmd -XPOST --data "{ \"certificate\": \"$(sed -z 's/\n/\\n/g' < "$dir/$name-chain.crt")\" }" \
        "$VAULT_ADDR/v1/$name/intermediate/set-signed"
done

exit 1
