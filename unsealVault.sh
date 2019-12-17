#!/bin/bash

dir=generated
caDir=ca

set -e

export VAULT_ADDR="https://vault.cerberus-systems.de"
export VAULT_CACERT="$dir/pki_int_outside-chain.crt"
export VAULT_CLIENT_CERT="$dir/vault-operator.crt"
export VAULT_CLIENT_KEY="$dir/vault-operator.key"

vaultKeys=$(cat vault_keys.txt)

for i in 1 2 3; do
    key=$(echo "$vaultKeys" | grep "Unseal Key $i:" | awk '{ print $NF }')

    echo "{ \"key\": \"$key\" }" | \
        curl -X PUT --data @- \
            --cacert "$VAULT_CACERT" --cert "$VAULT_CLIENT_CERT" \
            --key "$VAULT_CLIENT_KEY" "$VAULT_ADDR/v1/sys/unseal" > /dev/null
done

echo "Vault unsealed"
