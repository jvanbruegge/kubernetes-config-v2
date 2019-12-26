#!/bin/bash

echo "$(< ./customResources.yaml)
---
$(dhall-to-yaml --omit-empty --documents --file cert-manager.dhall)" | \
    kubectl apply -f -
