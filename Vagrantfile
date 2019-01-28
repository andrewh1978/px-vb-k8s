vb_dir = "#{ENV['HOME']}/VirtualBox\ VMs"
nodes = 3
disk_size = 20480
name = "px-test-cluster"
version = "2.0"

open("hosts", "w") do |f|
  f << "192.168.99.98 registry\n"
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
    sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config
    swapoff -a
    sed -i /swap/d /etc/fstab
    sed -i s/enabled=1/enabled=0/ /etc/yum/pluginconf.d/fastestmirror.conf
    mkdir /root/.ssh /etc/docker
    cp /vagrant/hosts /etc
    cp /vagrant/*.repo /etc/yum.repos.d
    cp /vagrant/id_rsa /root/.ssh
    cp /vagrant/id_rsa.pub /root/.ssh/authorized_keys
    cp /vagrant/docker /etc/sysconfig
    chmod 600 /root/.ssh/id_rsa
    modprobe br_netfilter
    sysctl -w net.bridge.bridge-nf-call-iptables=1 >/etc/sysctl.conf
    echo '{"insecure-registries":["registry:5000"]}' >/etc/docker/daemon.json
  SHELL

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
  end

  config.vm.define "registry" do |registry|
    registry.vm.hostname = "registry"
    registry.vm.network "private_network", ip: "192.168.99.98", virtualbox__intnet: true
    registry.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--name", "registry"]
      vb.memory = 384
    end
    registry.vm.provision "shell", inline: <<-SHELL
      ( yum install -y kubeadm docker
        systemctl start docker
        systemctl enable docker
        docker run -d -p 5000:5000 --restart=always --name registry registry:2
        PX_IMGS=$(curl -s "https://install.portworx.com/#{version}?kbver=$(kubectl version --short | awk -Fv '/Server Version: / {print \$3}')&b=true&s=%2Fdev%2Fsdb&m=eth1&d=eth1&c=#{name}&stork=true&st=k8s&lh=true" | awk '/image: /{print $2} /oci-monitor/{sub(/oci-monitor/,"px-enterprise",$2);print$2}' | sort -u)
        K8S_IMGS=$(kubeadm config images list)
        echo $PX_IMGS $K8S_IMGS | xargs -n1 -P0 docker pull
        echo -n $PX_IMGS $K8S_IMGS | xargs -n1 -d " " -i docker tag {} registry:5000/{}
        echo -n $PX_IMGS $K8S_IMGS | xargs -n1 -d " " -i docker push registry:5000/{}
        echo End
      ) &>/var/log/vagrant.bootstrap
    SHELL
  end

  config.vm.define "master" do |master|
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: "192.168.99.99", virtualbox__intnet: true
    master.vm.provider :virtualbox do |vb| 
      vb.customize ["modifyvm", :id, "--name", "master"]
      vb.memory = 2048
    end
    master.vm.provision "shell", inline: <<-SHELL
      ( yum install -y kubeadm docker
        systemctl start docker
        echo >/dev/tcp/registry/5000 || docker run -p 5000:5000 -d --restart=always --name registry -e REGISTRY_PROXY_REMOTEURL=http://registry-1.docker.io -v /opt/shared/docker_registry_cache:/var/lib/registry registry:2
        systemctl enable docker kubelet
        systemctl restart docker kubelet
        if echo >/dev/tcp/registry/5000; then
          kubeadm config images list | xargs -n1 -P0 -i docker pull registry:5000/{}
          kubeadm init --apiserver-advertise-address=192.168.99.99 --pod-network-cidr=10.244.0.0/16 --image-repository=registry:5000/k8s.gcr.io
        else
          curl -s "https://install.portworx.com/#{version}?kbver=$(kubectl version --short | awk -Fv '/Server Version: / {print \$3}')&b=true&s=%2Fdev%2Fsdb&m=eth1&d=eth1&c=#{name}&stork=true&st=k8s&lh=true" | awk '/image: /{print $2} /oci-monitor/{sub(/oci-monitor/,"px-enterprise",$2);print$2}' | sort -u | grep -v gcr.io | xargs -n1 -P0 docker pull &
          kubeadm config images list | xargs -n1 -P0 docker pull
          kubeadm init --apiserver-advertise-address=192.168.99.99 --pod-network-cidr=10.244.0.0/16
        fi
        mkdir /root/.kube
        cp /etc/kubernetes/admin.conf /root/.kube/config
        kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
        wait
        if echo >/dev/tcp/registry/5000; then
          kubectl apply -f "https://install.portworx.com/#{version}?kbver=$(kubectl version --short | awk -Fv '/Server Version: / {print \$3}')&b=true&s=%2Fdev%2Fsdb&m=eth1&d=eth1&c=#{name}&stork=true&st=k8s&lh=true&reg=registry:5000"
        else
          kubectl apply -f "https://install.portworx.com/#{version}?kbver=$(kubectl version --short | awk -Fv '/Server Version: / {print \$3}')&b=true&s=%2Fdev%2Fsdb&m=eth1&d=eth1&c=#{name}&stork=true&st=k8s&lh=true"
        fi
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
          systemctl restart docker kubelet
          if echo >/dev/tcp/registry/5000; then
            kubeadm config images list | grep 'kube-proxy\\|pause' | xargs -n1 -P0 -i docker pull registry:5000/{} &
            curl -s "https://install.portworx.com/#{version}?kbver=$(kubectl version --short | awk -Fv '/Server Version: / {print \$3}')&b=true&s=%2Fdev%2Fsdb&m=eth1&d=eth1&c=#{name}&stork=true&st=k8s&lh=true&reg=registry:5000" | awk '/image: /{print $2} /oci-monitor/{sub(/oci-monitor/,"px-enterprise",$2);print$2}' | sort -u | xargs -n1 -P0 docker pull &
          else
            kubeadm config images list | grep 'kube-proxy\\|pause' | xargs -n1 -P0 docker pull &
            curl -s "https://install.portworx.com/#{version}?kbver=$(kubectl version --short | awk -Fv '/Server Version: / {print \$3}')&b=true&s=%2Fdev%2Fsdb&m=eth1&d=eth1&c=#{name}&stork=true&st=k8s&lh=true" | awk '/image: /{print $2} /oci-monitor/{sub(/oci-monitor/,"px-enterprise",$2);print$2}' | sort -u | grep gcr.io | xargs -n1 -P0 docker pull &
          fi
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
