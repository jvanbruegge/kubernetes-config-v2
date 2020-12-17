#!/bin/bash

action=$1

kubectl $action -f ./customResources.yaml

echo "$(dhall-to-yaml --documents --file cert-manager.dhall)
---
$(dhall-to-yaml --file letsencrypt.dhall)
" | kubectl $action -f -
