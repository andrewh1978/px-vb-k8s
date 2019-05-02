vb_dir = "#{ENV['HOME']}/VirtualBox\ VMs"
nodes = 3
disk_size = 20480
name = "px-test-cluster"
version = "2.0"

if !File.exist?("id_rsa") or !File.exist?("id_rsa.pub")
    puts("Please create SSH keys before running vagrant up.")
    abort
end

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
    rm -f /swapfile
    rpm -e linux-firmware
    sed -i /swap/d /etc/fstab
    sed -i s/enabled=1/enabled=0/ /etc/yum/pluginconf.d/fastestmirror.conf
    mkdir -p /root/.ssh /etc/docker /repo/kubernetes /repo/centos7
    cp /vagrant/hosts /etc
    cp /vagrant/*.repo* /etc/yum.repos.d
    cp /vagrant/id_rsa /root/.ssh
    cp /vagrant/id_rsa.pub /root/.ssh/authorized_keys
    cp /vagrant/docker /etc/sysconfig
    chmod 600 /root/.ssh/id_rsa
    modprobe br_netfilter
    sysctl -w net.bridge.bridge-nf-call-iptables=1 >/etc/sysctl.conf
    echo '{"insecure-registries":["registry:5000"]}' >/etc/docker/daemon.json
    if (echo >/dev/tcp/registry/6000) 2>/dev/null; then
      cp /vagrant/CentOS-Base.repo.docker /etc/yum.repos.d/CentOS-Base.repo
    else
      cp /vagrant/CentOS-Base.repo.mirror /etc/yum.repos.d/CentOS-Base.repo
    fi
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
      ( yum install -y docker
        mv /etc/yum.repos.d/kubernetes.repo.new /etc/yum.repos.d/kubernetes.repo
        for url in $(yum deplist kubeadm | awk 'BEGIN { print "kubeadm" } ; /provider/ { print $2 }' | xargs yumdownloader --urls ); do curl -o /repo/kubernetes/$(echo $url | cut -f 2- -d -) $url; done
        yum localinstall -y /repo/kubernetes/*rpm
        curl -o /root/flannel.yml https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
        curl -o /root/px.yml "https://install.portworx.com/#{version}?kbver=$(kubectl version --short | awk -Fv '/Server Version: / {print \$3}')&b=true&s=%2Fdev%2Fsdb&m=eth1&d=eth1&c=#{name}&stork=true&st=k8s&lh=true"
        curl -o /root/px-reg.yml "https://install.portworx.com/#{version}?kbver=$(kubectl version --short | awk -Fv '/Server Version: / {print \$3}')&b=true&s=%2Fdev%2Fsdb&m=eth1&d=eth1&c=#{name}&stork=true&st=k8s&lh=true&reg=registry:5000"
        systemctl start docker
        systemctl enable docker
        #mount 192.168.0.5:/raid/share/repos/centos/7 /repo/centos7
        docker run --rm -v /repo/centos7:/var/www/html andrewh1978/centos7yumrepo /updaterepo.sh
        docker run -d -p 6000:80 -v /repo/centos7:/var/www/html andrewh1978/centos7yumrepo
        docker run -d -p 5000:5000 --restart=always --name registry registry:2
        FLANNEL_IMG=$(awk '/image.*amd64/ {print$2}' /root/flannel.yml | sort -u)
        PX_IMGS=$(cat /root/px.yml | awk '/image: /{print $2} /oci-monitor/{sub(/oci-monitor/,"px-enterprise",$2);print$2}' | sort -u)
        K8S_IMGS=$(kubeadm config images list)
        echo $PX_IMGS $K8S_IMGS $FLANNEL_IMG | xargs -n1 -P0 docker pull
        echo -n $PX_IMGS $K8S_IMGS $FLANNEL_IMG | xargs -n1 -d " " -i docker tag {} registry:5000/{}
        echo -n $PX_IMGS $K8S_IMGS $FLANNEL_IMG | xargs -n1 -d " " -i docker push registry:5000/{}
        sed 's#image: \\(.*amd64\\)#image: registry:5000/\\1#' /root/flannel.yml >/root/flannel-reg.yml
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
      ( yum install -y docker
        if echo >/dev/tcp/registry/5000; then
          ssh-keyscan registry 2>&1 | grep ssh-rsa >>/root/.ssh/known_hosts
          rsync -r -e ssh registry:/repo/kubernetes/ /repo/kubernetes/
          yum localinstall -y /repo/kubernetes/*rpm
        else
          systemctl start docker
          docker run -p 5000:5000 -d --restart=always --name registry -e REGISTRY_PROXY_REMOTEURL=http://registry-1.docker.io -v /opt/shared/docker_registry_cache:/var/lib/registry registry:2
          mv /etc/yum.repos.d/kubernetes.repo.new /etc/yum.repos.d/kubernetes.repo
          yum install -y kubeadm
        fi
        systemctl enable docker kubelet
        systemctl restart docker kubelet
        if echo >/dev/tcp/registry/5000; then
          ssh registry docker images | awk '/^registry.*gcr/ {print$1":"$2 }' | xargs -n1 -P0 docker pull
          kubeadm init --apiserver-advertise-address=192.168.99.99 --pod-network-cidr=10.244.0.0/16 --image-repository=registry:5000/k8s.gcr.io
        else
          curl -s "https://install.portworx.com/#{version}?kbver=$(kubectl version --short | awk -Fv '/Server Version: / {print \$3}')&b=true&s=%2Fdev%2Fsdb&m=eth1&d=eth1&c=#{name}&stork=true&st=k8s&lh=true" | awk '/image: /{print $2} /oci-monitor/{sub(/oci-monitor/,"px-enterprise",$2);print$2}' | sort -u | grep -v gcr.io | xargs -n1 -P0 docker pull &
          kubeadm config images list | xargs -n1 -P0 docker pull
          kubeadm init --apiserver-advertise-address=192.168.99.99 --pod-network-cidr=10.244.0.0/16
        fi
        mkdir /root/.kube
        cp /etc/kubernetes/admin.conf /root/.kube/config
        if echo >/dev/tcp/registry/5000; then
          ssh registry cat /root/flannel-reg.yml | kubectl apply -f -
          ssh registry cat /root/px-reg.yml | kubectl apply -f -
        else
          kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
          wait
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
        ( yum install -y docker
          if echo >/dev/tcp/registry/5000; then
            ssh-keyscan registry 2>&1 | grep ssh-rsa >>/root/.ssh/known_hosts
            rsync -r -e ssh registry:/repo/kubernetes/ /repo/kubernetes/
            yum localinstall -y /repo/kubernetes/*rpm
          else
            mv /etc/yum.repos.d/kubernetes.repo.new /etc/yum.repos.d/kubernetes.repo
            yum install -y kubeadm
          fi
          systemctl enable docker kubelet
          systemctl restart docker kubelet
          if echo >/dev/tcp/registry/5000; then
            ssh registry docker images | awk '/^registry.*gcr/ {print$1":"$2 }' | xargs -n1 -P0 docker pull &
            ssh registry cat /root/px-reg.yml | awk '/image: /{print $2} /oci-monitor/{sub(/oci-monitor/,"px-enterprise",$2);print$2}' | sort -u | xargs -n1 -P0 docker pull &
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
