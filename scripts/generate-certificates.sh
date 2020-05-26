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

    echo "$caPass" | \
        openssl req -new -nodes -newkey rsa:4096 -keyout "$caDir/ca.key" -out "$caDir/ca.crt" \
            -config "$caDir/ca.conf" -x509 -days 7300 -passin stdin

    [ -e "$dir" ] && rm -r "$dir"
fi

function generateIntermediateCA() {
    name="$1"
    if [ ! -e "$caDir/$name/ca.key" ] || [ ! -e "$caDir/$name/ca.crt" ]; then
        echo "Generating intermediate CA: $name"

        mkdir -p "$caDir/$name"

        touch "$caDir/$name/ca.index"
        openssl rand -hex 16 > "$caDir/$name/ca.serial"

        echo "(./openssl/kubernetes.dhall).$name" | dhall text > "$caDir/$name/ca.conf"

        openssl req -new -nodes -newkey rsa:4096 -keyout "$caDir/$name/ca.key" -out "$caDir/$name/ca.csr" \
            -config "$caDir/$name/ca.conf"

        echo -e "$caPass\ny\ny\n" | \
            openssl ca -config "$caDir/ca.conf" -cert "$caDir/ca.crt" -keyfile "$caDir/ca.key" \
                -extensions x509_ext -out "$caDir/$name/ca.crt" -passin stdin -in "$caDir/$name/ca.csr" -notext
    fi
}

generateIntermediateCA "kubernetesCA"
generateIntermediateCA "etcdCA"
generateIntermediateCA "frontProxyCA"

function generateCert() {
    name="$1"
    if [ ! -e "$dir/$name.key" ] || [ ! -e "$dir/$name.crt" ]; then
        echo "Generating client certificate for $name"

        echo "(./openssl/kubernetes.dhall).$name" | dhall text > "$dir/$name.conf"

        openssl req -new -nodes -newkey rsa:4096 -keyout "$dir/$name.key" \
            -out "$dir/$name.csr" -config "$dir/$name.conf"

        echo -e "$caPass\ny\ny\n" | \
            openssl ca -config "$caDir/ca.conf" -cert "$caDir/ca.crt" -keyfile "$caDir/ca.key" \
                -out "$dir/$name.crt" -passin stdin -infiles "$dir/$name.csr"

        rm "$dir/$name.csr" "$dir/$name.conf"
    fi
}

mkdir -p "$dir"

generateCert "admin"
generateCert "kubelet"
generateCert "kubeControllerManager"
generateCert "kubeScheduler"

function copyCert() {
    from=$1
    to=$2
    prefix=/etc/kubernetes/pki
    if [ -n "$(dirname "$to")" ]; then
        $SSH_COMMAND "sudo mkdir -p $prefix/$(dirname "$to")"
    fi
    $SSH_COMMAND "sudo tee $prefix/$to.crt >/dev/null" < "$from.crt"
    $SSH_COMMAND "sudo tee $prefix/$to.key >/dev/null" < "$from.key"
}

echo "Transfering certificates to server"
copyCert "$caDir/kubernetesCA/ca" "ca"
copyCert "$caDir/etcdCA/ca" "etcd/ca"
copyCert "$caDir/frontProxyCA/ca" "front-proxy-ca"

copyCert "$dir/admin" "admin"
copyCert "$dir/kubelet" "kubelet"
copyCert "$dir/kubeControllerManager" "controller-manager"
copyCert "$dir/kubeScheduler" "scheduler"
