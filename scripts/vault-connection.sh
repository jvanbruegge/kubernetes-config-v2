dir=generated

export VAULT_ADDR="https://vault.cerberus-systems.de"
export VAULT_CACERT="ca-chain.crt"
export VAULT_CLIENT_CERT="$dir/vault-operator.crt"
export VAULT_CLIENT_KEY="$dir/vault-operator.key"

rootToken=$(tail -n 1 vault_keys.txt)

function curlCmd {
    curl --cacert "$VAULT_CACERT" --cert "$VAULT_CLIENT_CERT" \
        --key "$VAULT_CLIENT_KEY" --header "X-Vault-Token: $rootToken" "$@"
}

