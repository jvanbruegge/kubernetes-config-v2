#!/bin/bash

dir=$1
action="apply"

if [ ! -z $2 ]; then
    action=$2
fi

if [ ! -e "$dir/apply.sh" ]; then
    dhall-to-yaml --omit-empty --documents --file "$dir/$dir.dhall" | \
        kubectl $action -f -
else
    cd "$dir"
    ./apply.sh $action
    cd ..
fi
