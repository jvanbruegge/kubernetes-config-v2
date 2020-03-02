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
