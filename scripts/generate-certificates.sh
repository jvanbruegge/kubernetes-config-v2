#!/bin/bash

set -euo pipefail

caDir=./ca
dir=./generated

# Get CA password
read -sr -p "Enter pass phrase for ca.key: " caPass
echo ""
read -sr -p "Verifying - Enter pass phrase for ca.key: " caPassCopy
echo ""

if [[ "$caPass" != "$caPassCopy" ]]; then
    echo -e "Error: Passwords not matching" > /dev/stderr
    exit 1
fi

# Generate CA
if [ ! -e "$caDir/ca.key" ]; then
    echo "Generating root CA and certificate"

    mkdir -p "$caDir"

    touch "$caDir/ca.index"
    openssl rand -hex 16 > "$caDir/ca.serial"

    dhall text --file openssl/ca.conf.dhall > "$caDir/ca.conf"

    echo "$caPass" | openssl genpkey -algorithm RSA -aes-256-cbc -pass stdin -out "$caDir/ca.key" -pkeyopt rsa_keygen_bits:4096

    chmod 400 "$caDir/ca.key"

    echo "$caPass" | openssl req -new -out "$caDir/ca.crt" -config "$caDir/ca.conf" -x509 -days 7300 -key "$caDir/ca.key" -passin stdin

    [ -e "$dir" ] && rm -r "$dir"
fi

function generateCert() {
    name="$1"
    if [ ! -e "$dir/$name.key" ] || [ ! -e "$dir/$name.crt" ]; then
        echo "Generating client certificate for $name"

        echo "./openssl/server.conf.dhall \"$name\"" | dhall text > "$dir/$name.conf"

        openssl req -new -nodes -newkey rsa:4096 -keyout "$dir/$name.key" \
            -out "$dir/$name.csr" -config "$dir/$name.conf"

        echo -e "$caPass\ny\ny\n" | \
            openssl ca -config ca/ca.conf -cert ca/ca.crt -keyfile ca/ca.key -out "$dir/$name.crt" -passin stdin -infiles "$dir/$name.csr"

        rm "$dir/$name.csr" "$dir/$name.conf"
    fi
}

mkdir -p "$dir"

generateCert "certtest"
