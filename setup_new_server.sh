#!/bin/bash

set -euo pipefail

if [ -e ".env" ]; then
    # shellcheck source=.env
    source .env
fi

if [ -z "$SERVER_USER" ]; then
    echo "You must define SERVER_USER e.g. with export SERVER_USER=vagrant" >&2
    exit 1
fi

if [ -z "$SERVER_ADDRESS" ]; then
    echo "You must define SERVER_ADDRESS e.g. with export SERVER_ADDRESS=192.168.99.100" >&2
    exit 1
fi

export SSH_COMMAND="ssh $SERVER_USER@$SERVER_ADDRESS"

echo "Trying to connect to server"
if ! $SSH_COMMAND "echo 'SSH connection to server succeeded'"; then
    echo "SSH connection to the server failed"
    exit 1
fi
$SSH_COMMAND 'mkdir -p checkpoints'

function runStep() {
    stepName=${1//-/ }
    red="\033[0;31m"
    green="\033[0;32m"
    yellow="\033[1;33m"
    nc="\033[0m"

    if ! $SSH_COMMAND stat "checkpoints/$1" >/dev/null 2>&1; then
        echo -e "${green}Running step '$stepName'${nc}"
        if ! ./scripts/"$1.sh"; then
            echo -e "${red}Step '$stepName' failed${nc}"
            exit 1
        fi

        echo -e "${green}Writing checkpoint for step $stepName${nc}"
        $SSH_COMMAND "touch checkpoints/$1"
    else
        echo -e "${yellow}Step '$stepName' already performed on the server${nc}"
    fi
}

runStep generate-certificates

runStep install-kubernetes
