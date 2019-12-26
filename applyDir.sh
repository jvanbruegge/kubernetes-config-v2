#!/bin/bash

dir=$1

if [ ! -e "$dir/apply.sh" ]; then
    dhall-to-yaml --omit-empty --documents --file "$dir/$dir.dhall" | \
        kubectl apply -f -
else
    cd "$dir"
    ./apply.sh
    cd ..
fi
