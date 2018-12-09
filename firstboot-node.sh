set -x
while ! ping -c1 -w1 8.8.8.8 ; do echo Waiting for network...; done
yum install -y device-mapper-persistent-data lvm2 docker
if [ $HOSTNAME != node1 ]; then
	while ! ssh -oConnectTimeout=1 -oStrictHostKeyChecking=no node1 docker images | grep -q px-enterprise; do
		sleep 1
	done
fi
yum install -y kubelet kubeadm kubectl
sed -i s/cgroup-driver=systemd/cgroup-driver=cgroupfs/g /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
cp /vagrant/docker /etc/sysconfig/docker
systemctl enable docker kubelet
systemctl start docker kubelet
while : ; do
	command=$(ssh -oConnectTimeout=1 -oStrictHostKeyChecking=no master kubeadm token create --print-join-command)
	[ $? -eq 0 ] && break
done
eval $command
systemctl disable firstboot
