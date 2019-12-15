#!/bin/bash

dir=$1
caDir=$2
name=$3

if [ -t 0 ]; then
    echo "Error: Expected CA key password on stdin via a pipe"
    exit 1
fi

set -e

read caPass < /dev/stdin

echo "Generating client certificate for $name"

mkdir -p "$dir"

echo "./user.conf.dhall \"$name\"" | dhall text > "$dir/$name.conf"

openssl req -new -nodes -newkey rsa:4096 -keyout "$dir/$name.key" \
    -out "$dir/$name.csr" -config "$dir/$name.conf"

echo "$caPass" | \
    openssl x509 -req -in "$dir/$name.csr" -CA "$caDir/ca.crt" \
        -CAkey "$caDir/ca.key" -out "$dir/$name.crt" -days 500 \
        -extensions v3_req -CAcreateserial -passin stdin

rm "$dir/$name.csr" "$dir/$name.conf"
