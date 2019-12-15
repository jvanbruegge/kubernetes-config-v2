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
