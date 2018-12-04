# What

This will provision a Kubernetes cluster, along with Portworx, on a local Virtualbox instance.

# How

1. Install [Virtualbox](https://www.virtualbox.org/wiki/Downloads).
2. Clone this repo and cd to it.
3. Edit `Vagrantfile` as necessary.
3. Generate SSH keys:
```
# ssh-keygen -t rsa -b 2048 -f id_rsa
```
This will allow SSH as root between the various nodes.
4. Start the cluster:
```
# vagrant up
```
5. Check the status of the Portworx cluster:
```
# vagrant ssh node1
# pxctl status
```
