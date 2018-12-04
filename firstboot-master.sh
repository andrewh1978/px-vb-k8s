export HOME=/root
systemctl disable firstboot
mkdir /root/.kube
kubeadm init --apiserver-advertise-address=192.168.99.99 --pod-network-cidr=10.244.0.0/16 >>/var/tmp/firstboot.log
cp /etc/kubernetes/admin.conf /root/.kube/config
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml >>/var/tmp/firstboot.log
kubectl apply -f 'https://install.portworx.com/2.0?kbver=1.9.10&b=true&s=%2Fdev%2Fsdb&m=eth1&d=eth1&c=px-demo&stork=true&st=k8s' >>/var/tmp/firstboot.log
