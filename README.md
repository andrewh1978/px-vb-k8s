# What

This will provision a Kubernetes cluster, along with Portworx, on a local Virtualbox instance.

# How

1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads).
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
$ vagrant ssh node1
[vagrant@node1 ~]$ sudo /opt/pwx/bin/pxctl status
Status: PX is operational
License: Trial (expires in 31 days)
Node ID: node1
	IP: 192.168.99.101
 	Local Storage Pool: 1 pool
	POOL	IO_PRIORITY	RAID_LEVEL	USABLE	USED	STATUS	ZONE	REGION
	0	LOW		raid0		4.0 GiB	1.5 GiB	Online	default	default
	Local Storage Devices: 1 device
	Device	Path		Media Type		Size		Last-Scan
	0:1	/dev/sdb	STORAGE_MEDIUM_MAGNETIC	4.0 GiB		04 Dec 18 10:55 UTC
	total			-			4.0 GiB
Cluster Summary
	Cluster ID: px-demo
	Cluster UUID: e8de18ad-3d77-45d4-bf64-99bc5a37f22f
	Scheduler: kubernetes
	Nodes: 2 node(s) with storage (2 online)
	IP		ID	StorageNode	Used	Capacity	Status	StorageStatus	Version		Kernel				OS
	192.168.99.102	node2	Yes		1.5 GiB	4.0 GiB		Online	Up		1.6.1.3-61b6770	3.10.0-862.14.4.el7.x86_64	CentOS Linux 7 (Core)
	192.168.99.101	node1	Yes		1.5 GiB	4.0 GiB		Online	Up (This node)	1.6.1.3-61b6770	3.10.0-862.14.4.el7.x86_64	CentOS Linux 7 (Core)
Global Storage Pool
	Total Used    	:  3.1 GiB
	Total Capacity	:  8.0 GiB
```
