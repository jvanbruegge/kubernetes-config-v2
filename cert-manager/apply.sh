#!/usr/bin/env bash

action=$1
dry=$2

if [ "$dry" == "true" ]; then
  cat ./cert-manager.yaml
  dhall-to-yaml --file letsencrypt.dhall
else
  kubectl $action -f ./cert-manager.yaml
  echo "$(dhall-to-yaml --file letsencrypt.dhall)" | kubectl $action -f -
fi
