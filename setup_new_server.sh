#!/bin/bash

dir="$(pwd)/generated"
caDir="$(pwd)/ca"

# Get this information once, so we do not ask this again later
# when we sign the intermediate CAs or the client certificates
read -s -p "Enter pass phrase for $caDir/ca.key: " caPass
echo ""
read -s -p "Verifying - Enter pass phrase for $caDir/ca.key: " caPassCopy
echo ""

if [[ $caPass != $caPassCopy ]]; then
    echo "Error: Passwords not matching" > /dev/stderr
    exit 1
fi

cat ~/.ssh/known_hosts | grep -v "192.168.99.100" > ~/.ssh/known_hosts

set -e

./minikube.sh start

[ -d "$dir" ] && rm -r "$dir"

for f in $(< services.txt); do
    minikube ssh "su -c 'mkdir -p /data/$f'"
done

# Set up certificates
cd openssl
./generateCA.sh "$caDir" "$caPass"

echo "$caPass" | ./generateCertificate.sh "$dir" "$caDir" "vault"
cd ..

function transferVaultCert() {
    echo "Copying vault certificate and key to server"
    minikube ssh 'su -c "mkdir -p /data/vault/ssl"'

    caFile="$caDir/ca.crt"
    if [ -e "$dir/pki_int_outside-chain.crt" ]; then
        caFile="$dir/pki_int_outside-chain.crt"
    fi

    for file in "$dir/vault.key" "$dir/vault.crt" "$caFile" ; do
        filename=$(basename $file)
        if [[ "$file" == "$caFile" ]]; then
            filename="ca.crt"
        fi

        ssh -i $(minikube ssh-key) -o StrictHostKeyChecking=no docker@$(minikube ip) \
            "su -c 'cat > /data/vault/ssl/$filename'" < $file
    done
    rm "$dir/vault.key" "$dir/vault.crt"
}

transferVaultCert

# Deploy HAProxy & vault
dhall-to-yaml --omit-empty --documents --file haproxy/haproxy.dhall | \
    kubectl apply -f -

dhall-to-yaml --omit-empty --documents --file vault/vault.dhall | \
    kubectl apply -f -

echo "Waiting for vault to start up"

sleep 5
kubectl wait --namespace=vault --for=condition=ready --timeout=3000s pods vault-0

# Configure vault
cd openssl
echo "$caPass" | ./generateCertificate.sh "$dir" "$caDir" "vault-operator"
cd ..

export VAULT_ADDR="https://vault.cerberus-systems.de"
export VAULT_CACERT="$caDir/ca.crt"
export VAULT_CLIENT_CERT="$dir/vault-operator.crt"
export VAULT_CLIENT_KEY="$dir/vault-operator.key"

vaultKeys=$(vault operator init 2> /dev/null)

echo "$vaultKeys" > vault_keys.txt
echo "Initialized vault - find keys in vault_keys.txt"

for i in 1 2 3; do
    key=$(echo "$vaultKeys" | grep "Unseal Key $i:" | awk '{ print $NF }')

    echo "{ \"key\": \"$key\" }" | \
        curl -X PUT --data @- \
            --cacert "$VAULT_CACERT" --cert "$VAULT_CLIENT_CERT" \
            --key "$VAULT_CLIENT_KEY" "$VAULT_ADDR/v1/sys/unseal" > /dev/null
done

token=$(cat vault_keys.txt | grep "Initial Root Token: " | awk '{ print $NF }')
export VAULT_TOKEN="$token"

cd openssl
echo "./ca.conf.dhall \"$caDir\"" | dhall text > "$dir/ca.conf"
cd ..

for name in pki_int_outside pki_int_inside; do

    echo "Generating and signing $name"

    vault secrets enable --path="$name" pki

    vault secrets tune -max-lease-ttl=720h "$name"

    vault write "$name/intermediate/generate/internal" \
        common_name="Cerberus Systems Intermediate CA" \
        organization="Cerberus Systems" \
        ttl=43800h -format=json | \
        jq -r .data.csr > "$dir/$name.csr"

    echo "$caPass"$'\ny\ny\n' | \
        openssl ca -extensions intermediate-ca_ext -in "$dir/$name.csr" \
            -out "$dir/$name.crt" -days 720 -config "$dir/ca.conf" \
            -passin stdin -notext

    cat "$dir/$name.crt" "$caDir/ca.crt" > "$dir/$name-chain.crt"

    vault write "$name/intermediate/set-signed" certificate="@$dir/$name-chain.crt"

    vault write "$name/roles/get-cert" \
        allowed_domains=cerberus-systems.de,cerberus-systems.com,svc.cluster.local \
        allow_subdomains=true max_ttl=1860h
done

# Let vault generate a certificate for itself
for name in vault vault-operator; do
    result=$(vault write "pki_int_outside/issue/get-cert" -format="json" \
        common_name="$name.cerberus-systems.de" \
        alt_names="$name.cerberus-systems.com,$name.$name.svc.cluster.local")

    echo "$result" | jq -r '.data.certificate' > "$dir/$name.crt"
    echo "$result" | jq -r '.data.private_key' > "$dir/$name.key"
done

transferVaultCert

kubectl delete --namespace=vault statefulsets.apps vault
kubectl wait --namespace=vault --for=delete --timeout=3000s pods vault-0

dhall-to-yaml --omit-empty --documents --file vault/vault.dhall | \
    kubectl apply -f -

export VAULT_CACERT="$dir/pki_int_outside.crt"
sleep 5
kubectl wait --namespace=vault --for=condition=ready --timeout=3000s pods vault-0

./unsealVault.sh

vault auth enable kubernetes

echo "Configuring vault kubernetes authentification"

accountPath="/run/secrets/kubernetes.io/serviceaccount"
kubeCert=$(kubectl exec --namespace=vault -it vault-0 -- sh -c "cat $accountPath/ca.crt")
serviceToken=$(kubectl exec --namespace=vault -it vault-0 -- sh -c "cat $accountPath/token")

echo "$kubeCert" > "$dir/kubernetes_ca.crt"

vault write auth/kubernetes/config \
    kubernetes_host='https://kubernetes.default.svc.cluster.local' \
    kubernetes_ca_cert="@$dir/kubernetes_ca.crt" \
    token_reviewer_jwt="$serviceToken"

dhall text --file vault/policies/get-cert.hcl.dhall \
   | vault policy write get-cert -

vault write auth/kubernetes/role/get-cert \
   bound_service_account_names=default \
   bound_service_account_namespaces='*' \
   generate_lease=true policies=get-cert ttl=2h

echo "Enabling vault key-value backend"
vault secrets enable -version=2 kv

dhall-to-yaml --omit-empty --documents --file ldap/ldap.dhall | \
    kubectl apply -f -

adminPass=$(tr -dc _A-Za-z-0-9 < /dev/urandom | head -c${1:-32})
configPass=$(tr -dc _A-Za-z-0-9 < /dev/urandom | head -c${1:-32})

echo "Saving ldap admin passwords in vault"
echo "$configPass" | vault kv put kv/ldap config-admin=-
echo "$adminPass" | vault kv patch kv/ldap admin=-

echo "Waiting for OpenLDAP to start, this will take a while"
kubectl wait --namespace=ldap --for=condition=ready --timeout=3000s pods openldap-0
{ kubectl logs --namespace=ldap -f openldap-0 & } | sed -n '/slapd starting/q'

sleep 2

adminSHA=$(echo $adminPass | slappasswd -h {SSHA} -T /dev/fd/0)
configSHA=$(echo $configPass | slappasswd -h {SSHA} -T /dev/fd/0)

chPassLdif=$(echo "./ldap/ldif/chPassword.ldif.dhall \"$adminSHA\" \"$configSHA\"" | dhall text)
chTreeLdif=$(echo "./ldap/ldif/chTreePassword.ldif.dhall \"$adminSHA\"" | dhall text)

# First seed the DIT
kubectl exec --namespace=ldap -it openldap-0 -- \
    bash -c "echo \"$(< ldap/ldif/objectclasses.ldif)\" | ldapadd -Y EXTERNAL -H ldapi://"
kubectl exec --namespace=ldap -it openldap-0 -- \
    bash -c "echo \"$(< ldap/ldif/dit.ldif)\" | ldapadd -H ldaps://localhost -D 'cn=admin,dc=cerberus-systems,dc=de' -x -w admin"

# Then change the passwords
kubectl exec --namespace=ldap -it openldap-0 -- \
    bash -c "echo \"$chPassLdif\" | ldapmodify -Y EXTERNAL -H ldapi://"
kubectl exec --namespace=ldap -it openldap-0 -- \
    bash -c "echo \"$chTreeLdif\" | ldapmodify -H ldaps://localhost -D 'cn=admin,dc=cerberus-systems,dc=de' -x -w admin"
