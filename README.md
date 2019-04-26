# What

This will provision a Kubernetes/PX cluster, and an optional private registry VM, on a local VirtualBox.

If the registry VM is used, it will prepopulate a yum repo running in a Docker container (this could take several minutes), as well as a local registry with all of the Kubernetes and PX images, so the whole cluster can be built without the requirement for an outbound Internet connection. Once this registry is up, on a 2018 MBP with 16GB RAM, the time taken to provison a cluster comprising a master and 3 workers is approximately 12 minutes (or 6 minutes for a single worker node cluster).

# How

1. Install [Vagrant](https://www.vagrantup.com/downloads.html) and [VirtualBox](https://www.virtualbox.org/wiki/Downloads).
2. Clone this repo and cd to it.
3. Edit top section of `Vagrantfile` as necessary. There is also a mount command that has been commented out in the registry section to persist the yum repo - uncomment and edit as appropriate if you wish to use it.
4. Edit CentOS-Base.repo.mirror as necessary.
5. Generate SSH keys:
```
$ ssh-keygen -t rsa -b 2048 -f id_rsa
```
This will allow SSH as root between the various nodes.

6. Start the registry VM (optional):
```
vagrant up registry
```

7. Start the cluster:
```
$ vagrant up
```

8. Check the status of the Portworx cluster:
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

# Notes

The object is to provision everything on top of a base CentOS installation to make it easier to test different software versions. This is inherently slower than baking everything into a prebuilt image.

After each VM is provisioned, the bootstrap process runs in the background (so Vagrant can continue provisioning the subsequent nodes in parallel). Various parts of the process are also run in the background and images prepulled to reduce bottlenecks.

The process logs to `/var/log/vagrant.boostrap` on each node. When the process is completed, the line "End" is logged. If you wish to use the private registry VM, it *must* complete provisioning, so all of the Docker images have been pulled before you try to provision any of the cluster.

If you choose not to use the private registry, a Docker registry cache will run on the master node, and worker nodes will pull all of their docker.io images via the proxy to minimise bandwidth usage.
