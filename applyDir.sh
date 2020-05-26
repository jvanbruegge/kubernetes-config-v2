#!/bin/bash

set -eo pipefail

dir=$1
action="apply"

if [ -n "$2" ]; then
    action=$2
fi

if [ ! -e "$dir/apply.sh" ]; then
    if [ -e ".env" ]; then
        # shellcheck source=.env
        source .env
    fi

    ssh "$SERVER_USER@$SERVER_ADDRESS" "mkdir -p /data/$dir"

    dhall-to-yaml --documents --file "$dir/$dir.dhall" | \
        kubectl "$action" -f -
else
    cd "$dir" || exit 1
    ./apply.sh "$action"
    cd ..
fi
