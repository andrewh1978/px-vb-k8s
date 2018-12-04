# What

This will provision a Kubernetes cluster, along with Portworx, on a local VirtualBox instance.

# How

1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads).
2. Clone this repo and cd to it.
3. Edit `Vagrantfile` as necessary.
4. Generate SSH keys:
```
$ ssh-keygen -t rsa -b 2048 -f id_rsa
```
This will allow SSH as root between the various nodes.

5. Start the cluster:
```
$ vagrant up
```

6. Check the status of the Portworx cluster:
```
$ vagrant ssh node1
[vagrant@node1 ~]$ sudo /opt/pwx/bin/pxctl status
Status: PX is operational
License: Trial (expires in 31 days)
Node ID: fdaadec4-7062-499b-97b0-6bcdda1444e6
	IP: 192.168.99.101
 	Local Storage Pool: 1 pool
	POOL	IO_PRIORITY	RAID_LEVEL	USABLE	USED	STATUS	ZONE	REGION
	0	LOW		raid0		4.0 GiB	1.5 GiB	Online	default	default
	Local Storage Devices: 1 device
	Device	Path		Media Type		Size		Last-Scan
	0:1	/dev/sdb	STORAGE_MEDIUM_MAGNETIC	4.0 GiB		04 Dec 18 14:26 UTC
	total			-			4.0 GiB
Cluster Summary
	Cluster ID: px-demo
	Cluster UUID: 197f6ebd-6030-4894-a2ed-8f7426cbc414
	Scheduler: kubernetes
	Nodes: 2 node(s) with storage (2 online)
	IP		ID					SchedulerName	StorageNode	Used	Capacity	Status	StorageStatus	Version		Kernel				OS
	192.168.99.101	fdaadec4-7062-499b-97b0-6bcdda1444e6	node1		Yes		1.5 GiB	4.0 GiB		Online	Up (This node)	2.0.0.0-98ffec5	3.10.0-862.14.4.el7.x86_64	CentOS Linux 7 (Core)
	192.168.99.102	b87ad7a5-394e-4b8b-9849-ec5628caebee	node2		Yes		1.5 GiB	4.0 GiB		Online	Up		2.0.0.0-98ffec5	3.10.0-862.14.4.el7.x86_64	CentOS Linux 7 (Core)
Global Storage Pool
	Total Used    	:  3.1 GiB
	Total Capacity	:  8.0 GiB
```
