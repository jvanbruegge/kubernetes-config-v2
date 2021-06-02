#!/bin/bash

action=$1
dry=$2

if [ "$dry" == "true" ]; then
    echo "$(dhall-to-yaml --documents --file cert-manager.dhall)
---
$(dhall-to-yaml --file letsencrypt.dhall)
"
else
    kubectl $action -f ./customResources.yaml

    echo "$(dhall-to-yaml --documents --file cert-manager.dhall)
---
$(dhall-to-yaml --file letsencrypt.dhall)
" | kubectl $action -f -
fi
