#!/bin/bash

cmd=$1

if [[ $cmd = "delete" ]]; then
    # This is a workaround until https://github.com/kubernetes/minikube/issues/951 is fixed
    VBOX_CONFIG_DIR=.config

    kill -9 $(ps aux | grep -i "vboxsvc\|vboxnetdhcp" | awk '{print $2}') 2>/dev/null

    if [[ -f ~/$VBOX_CONFIG_DIR/VirtualBox/HostInterfaceNetworking-vboxnet0-Dhcpd.leases ]] ; then
        rm  ~/$VBOX_CONFIG_DIR/VirtualBox/HostInterfaceNetworking-vboxnet0-Dhcpd.leases
    fi
fi

minikube $cmd
