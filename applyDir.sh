#!/bin/bash

set -eo pipefail

dir=$1
action="apply"

if [ -z "$1" ]; then
    echo "Usage ./applyDir.sh <directory>"
    exit 1
fi

if [ -n "$2" ]; then
    action=$2
fi

if [ ! -e "$dir/apply.sh" ]; then
    if [ -z "$SERVER_USER" ]; then
        echo "Please set SERVER_USER and SERVER_ADDRESS"
        exit 1
    fi
    ssh "$SERVER_USER@$SERVER_ADDRESS" "mkdir -p /data/$dir"

    dhall-to-yaml --documents --file "$dir/$dir.dhall" | \
        kubectl "$action" -f -
else
    cd "$dir" || exit 1
    ./apply.sh "$action"
    cd ..
fi
