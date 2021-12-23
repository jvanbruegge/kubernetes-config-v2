#!/usr/bin/env bash

set -e

sed -e "s/\$SERVER_USER/$SERVER_USER/g" -e "s/\$SERVER_ADDRESS/$SERVER_ADDRESS/g" ./scripts/install-kubernetes-remote.sh \
    | $SSH_COMMAND 'cat | bash -s'

echo "Setting up kubectl"
mkdir -p "$HOME/.kube"
$SSH_COMMAND 'sudo cat /etc/kubernetes/admin.conf' > "$HOME/.kube/config"
sudo chown "$(id -u)":"$(id -g)" "$HOME/.kube/config"
