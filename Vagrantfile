vb_dir = "#{ENV['HOME']}/VirtualBox\ VMs"
nodes = 3
disk_size = 20480

open("hosts", "w") do |f|
  f << "192.168.99.99 master\n"
  (1..nodes).each do |n|
    f << "192.168.99.10#{n} node#{n}\n"
  end
end

Vagrant.configure("2") do |config|

  config.vm.box = "centos/7"
  config.vm.box_check_update = true
  config.vm.provision "shell", inline: <<-SHELL
    setenforce 0
    swapoff -a
    sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config
    sed -i /swap/d /etc/fstab
    sed -i s/enabled=1/enabled=0/ /etc/yum/pluginconf.d/fastestmirror.conf
    mkdir /root/.ssh
    cp /vagrant/{sysctl.conf,hosts} /etc
    cp /vagrant/*.repo /etc/yum.repos.d
    cp /vagrant/id_rsa /root/.ssh
    cp /vagrant/id_rsa.pub /root/.ssh/authorized_keys
    cp /vagrant/docker /etc/sysconfig
    chmod 600 /root/.ssh/id_rsa
    modprobe br_netfilter
    sysctl -p
  SHELL

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 4
  end

  config.vm.define "master" do |master|
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: "192.168.99.99", virtualbox__intnet: true
    master.vm.provider :virtualbox do |vb| 
      vb.customize ["modifyvm", :id, "--name", "master"]
      vb.memory = 2048
    end
    master.vm.provision "shell", inline: <<-SHELL
      ( yum install -y docker kubeadm
        systemctl start docker
        docker run -p 5000:5000 -d --restart=always --name registry -e REGISTRY_PROXY_REMOTEURL=http://registry-1.docker.io -v /opt/shared/docker_registry_cache:/var/lib/registry registry:2
        systemctl restart docker
        (docker pull portworx/oci-monitor:2.0.0.1 ; docker pull openstorage/stork ; docker pull portworx/px-enterprise:2.0.0.1) &
        kubeadm config images pull &
        systemctl enable docker kubelet
        systemctl start kubelet
        mkdir /root/.kube
        wait %2
        kubeadm init --apiserver-advertise-address=192.168.99.99 --pod-network-cidr=10.244.0.0/16
        cp /etc/kubernetes/admin.conf /root/.kube/config
        kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
        wait %1
        kubectl apply -f 'https://install.portworx.com/2.0?kbver=1.13.1&b=true&s=%2Fdev%2Fsdb&m=eth1&d=eth1&c=px-demo&stork=true&st=k8s&lh=true'
        echo End
      ) &>/var/log/vagrant.bootstrap &
    SHELL
  end

  (1..nodes).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.hostname = "node#{i}"
      node.vm.network "private_network", ip: "192.168.99.10#{i}", virtualbox__intnet: true
      if i === 1
        node.vm.network "forwarded_port", guest: 32678, host: 32678
      end
      node.vm.provider "virtualbox" do |vb| 
        vb.memory = 3072
        vb.customize ["modifyvm", :id, "--name", "node#{i}"]
        if File.exist?("#{vb_dir}/disk#{i}.vdi")
          vb.customize ['closemedium', "#{vb_dir}/disk#{i}.vdi", "--delete"]
        end
        vb.customize ['createmedium', 'disk', '--filename', "#{vb_dir}/disk#{i}.vdi", '--size', disk_size]
        vb.customize ['storageattach', :id, '--storagectl', 'IDE', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', "#{vb_dir}/disk#{i}.vdi"]
      end
      node.vm.provision "shell", inline: <<-SHELL
        ( yum install -y kubeadm docker
          systemctl enable docker kubelet
          systemctl start docker kubelet
          kubeadm config images pull &
          while : ; do
            command=$(ssh -oConnectTimeout=1 -oStrictHostKeyChecking=no master kubeadm token create --print-join-command)
            [ $? -eq 0 ] && break
            sleep 5
          done
          wait
          eval $command
          echo End
        ) &>/var/log/vagrant.bootstrap &
      SHELL
    end
  end

end
