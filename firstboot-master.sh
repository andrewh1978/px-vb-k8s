export HOME=/root
systemctl disable firstboot
mkdir /root/.kube
kubeadm init --apiserver-advertise-address=192.168.99.99 --pod-network-cidr=10.244.0.0/16 >>/var/tmp/firstboot.log
cp /etc/kubernetes/admin.conf /root/.kube/config
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml >>/var/tmp/firstboot.log
while : ; do
	t=$(kubectl get nodes | tail -n +2 | grep -v master | wc -l)
	if [ $t -eq 0 ]; then
		echo No worker nodes in cluster
	else
		n=$(kubectl get nodes | tail -n +2 | grep -v ' Ready ' | wc -l)
		[ $n -eq 0 ] && break
		echo Waiting for $n/$t worker nodes
		sleep 1
	fi
done >>/var/tmp/firstboot.log
kubectl apply -f 'https://install.portworx.com/1.6?kbver=1.9.10&b=true&s=%2Fdev%2Fsdb&m=eth1&d=eth1&c=px-demo&stork=true&st=k8s' >>/var/tmp/firstboot.log
