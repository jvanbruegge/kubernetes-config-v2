#!/bin/bash

set -euo pipefail

# Set up network config
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee /etc/sysctl.d/99-kubernetes.conf > /dev/null

echo "kube-master" | sudo tee /etc/hostname > /dev/null

sudo apt-get update
sudo apt-get install -y software-properties-common

# Install docker
if ! docker -v >/dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get install -y docker-ce
    sudo usermod -aG docker "$SERVER_USER"
fi

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Install kubernetes
if ! kubectl version; then
    sudo apt-get install -y apt-transport-https
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubeadm kubelet kubernetes-cni

    sudo tee /etc/docker/daemon.json >/dev/null <<EOF
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m"
    },
    "storage-driver": "overlay2"
}
EOF

    sudo systemctl restart docker
fi

# Set up kubernetes
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address="$SERVER_ADDRESS" \
    --node-name kube-master

mkdir "$HOME/.kube"
sudo cp /etc/kubernetes/admin.conf "$HOME/.kube/"
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/admin.conf"
export KUBECONFIG=$HOME/.kube/admin.conf
echo "export KUBECONFIG=$HOME/.kube/admin.conf" >> "$HOME/.bashrc"

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

kubectl taint nodes --all node-role.kubernetes.io/master-

sudo mkdir -p /data
sudo chown -R "$SERVER_USER:$SERVER_USER" /data

echo "Waiting for master node to become ready"
kubectl wait --for=condition=ready --timeout=120s nodes/kube-master > /dev/null
