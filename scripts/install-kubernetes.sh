#!/bin/bash

set -e

sed -e "s/\$SERVER_USER/$SERVER_USER/g" -e "s/\$SERVER_ADDRESS/$SERVER_ADDRESS/g" ./scripts/install-kubernetes-remote.sh \
    | $SSH_COMMAND 'cat | bash -s'