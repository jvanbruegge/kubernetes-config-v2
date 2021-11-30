#!/usr/bin/env bash

set -eo pipefail
set -o xtrace

dir=$1
action="apply"

usage="Usage ./applyDir.sh <directory> [action] [--dry-run]"

if [ -z "$1" ]; then
    echo "$usage"
    exit 1
fi

dry="false"
if [ -n "$2" ]; then
    if [ "$2" == "--dry-run" ]; then
        dry="true"
    else
        action="$2"
    fi
fi

if [ -n "$3" ]; then
    if [ "$3" == "--dry-run" ]; then
        dry="true"
    else
        echo "$usage"
        exit 1
    fi
fi

if [ ! -e "$dir/apply.sh" ]; then
    if [ "$dry" == "false" ]; then
        if [ -z "$SERVER_USER" ]; then
            echo "Please set SERVER_USER and SERVER_ADDRESS"
            exit 1
        fi
        ssh "$SERVER_USER@$SERVER_ADDRESS" "mkdir -p /data/$dir"

        dhall-to-yaml --documents --file "$dir/$dir.dhall" | \
            kubectl "$action" -f -
    else
        dhall-to-yaml --documents --file "$dir/$dir.dhall"
    fi
else
    cd "$dir" || exit 1
    ./apply.sh "$action" "$dry"
    cd ..
fi
