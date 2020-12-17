# My kubernetes setup

## Prerequisites (for setting up a server from scratch)

The install script will need ssh access to the server that is expected to run a fresh Ubuntu server 18.04 install.

To set up such a server for development, run

```
vagrant up
vagrant ssh -c 'cat >> .ssh/authorized_keys' < ~/.ssh/id_rsa.pub
```

The following Arch packages (or other distro's equivalents) must be installed:

```
curl
kubectl
openldap
vagrant
vault
```

## Stuff to do on a server beforehand

This assumes that you are connected to the server with an ssh key and not a password.

```bash
# Setup new user
sudo useradd kube
sudo mkdir -p /home/kube/.ssh
sudo cp .ssh/authorized_keys /home/kube/.ssh/
sudo chown -R kube:kube /home/kube
echo 'kube ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers

echo "kube-master" > /etc/hostname
reboot
```

After that you can run `setup_new_server.sh`
