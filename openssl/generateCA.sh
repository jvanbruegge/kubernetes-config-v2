#!/bin/bash

dir=$1
pass=$2

set -e

if [ ! -e "$dir" ]; then
    echo "Generating root CA and certificate"

    mkdir -p "$dir"

    touch "$dir/ca.index"
    openssl rand -hex 16 > "$dir/ca.serial"

    echo "./ca.conf.dhall \"$dir\"" | dhall text > "$dir/ca.conf"

    echo "$pass" | \
        openssl genpkey -algorithm RSA -aes-256-cbc -pass stdin -out "$dir/ca.key" \
            -pkeyopt rsa_keygen_bits:4096

    chmod 400 "$dir/ca.key"

    echo "$pass" | \
        openssl req -new -out "$dir/ca.crt" -config "$dir/ca.conf" \
            -x509 -days 7300 -sha256 -extensions root-ca_ext \
            -key "$dir/ca.key" -passin stdin

    rm "$dir/ca.conf"
fi
