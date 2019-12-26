#!/bin/bash

action=$1

echo "$(< ./customResources.yaml)
---
$(dhall-to-yaml --omit-empty --documents --file cert-manager.dhall)
---
$(dhall-to-yaml --file letsencrypt.dhall)
" | kubectl $action -f -
