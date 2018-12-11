export HOME=/root
while ! ping -c1 -w1 8.8.8.8 ; do echo Waiting for network...; done
systemctl disable firstboot
yum install -y docker
systemctl start docker
docker run -p 5000:5000 -d --restart=always --name registry -e REGISTRY_PROXY_REMOTEURL=http://registry-1.docker.io -v /opt/shared/docker_registry_cache:/var/lib/registry registry:2
cp /vagrant/docker /etc/sysconfig/docker
systemctl restart docker
docker pull portworx/oci-monitor
docker pull openstorage/stork
docker pull portworx/px-enterprise:2.0.0.1
yum install -y device-mapper-persistent-data lvm2 kubelet kubeadm kubectl
sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl enable docker kubelet
systemctl start kubelet
mkdir /root/.kube
kubeadm init --apiserver-advertise-address=192.168.99.99 --pod-network-cidr=10.244.0.0/16
cp /etc/kubernetes/admin.conf /root/.kube/config
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f 'https://install.portworx.com/2.0?kbver=1.9.10&b=true&s=%2Fdev%2Fsdb&m=eth1&d=eth1&c=px-demo&stork=true&st=k8s'
