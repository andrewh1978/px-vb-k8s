vb_dir = "#{ENV['HOME']}/VirtualBox\ VMs"
nodes = 2
disk_size = 4096

Vagrant.configure("2") do |config|

  config.vm.box = "centos/7"
  config.vm.box_check_update = true
  config.vm.provision "file", source: "kubernetes.repo", destination: "/tmp/kubernetes.repo"
  config.vm.provision "file", source: "sysctl.conf", destination: "/tmp/sysctl.conf"
  config.vm.provision "file", source: "hosts", destination: "/tmp/hosts"
  config.vm.provision "file", source: "CentOS-Base.repo", destination: "/tmp/CentOS-Base.repo"
  config.vm.provision "file", source: "firstboot.service", destination: "/tmp/firstboot.service"
  config.vm.provision "file", source: "id_rsa.pub", destination: "/tmp/id_rsa.pub"
  config.vm.provision "file", source: "id_rsa", destination: "/tmp/id_rsa"
  config.vm.provision "shell", inline: <<-SHELL
    setenforce 0
    sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
    sed -i /swap/d /etc/fstab
    modprobe br_netfilter
    mkdir /root/.ssh
    cp /tmp/sysctl.conf /tmp/hosts /etc
    cp /tmp/*.repo /etc/yum.repos.d
    cp /tmp/firstboot.service /etc/systemd/system
    cp /tmp/id_rsa /root/.ssh
    cp /tmp/id_rsa.pub /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/id_rsa
    sysctl -p
    yum install -y device-mapper-persistent-data lvm2 kubelet kubeadm kubectl docker
    sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    systemctl enable docker kubelet firstboot
  SHELL

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
  end

  config.vm.define "master" do |master|
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: "192.168.99.99", virtualbox__intnet: true
    master.vm.provider :virtualbox do |vb| 
      vb.customize ["modifyvm", :id, "--name", "master"]
      vb.memory = 1024
    end
    master.vm.provision "file", source: "firstboot-master.sh", destination: "/tmp/firstboot.sh"
    master.vm.provision "shell", inline: <<-SHELL
      cp /tmp/firstboot.sh /root
      reboot
    SHELL
  end

  (1..nodes).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.hostname = "node#{i}"
      node.vm.network "private_network", ip: "192.168.99.10#{i}", virtualbox__intnet: true
      node.vm.provider "virtualbox" do |vb| 
        vb.memory = 3072
        vb.customize ["modifyvm", :id, "--name", "node#{i}"]
        if File.exist?("#{vb_dir}/disk#{i}.vdi")
          vb.customize ['closemedium', "#{vb_dir}/disk#{i}.vdi", "--delete"]
        end
        vb.customize ['createmedium', 'disk', '--filename', "#{vb_dir}/disk#{i}.vdi", '--size', disk_size]
        vb.customize ['storageattach', :id, '--storagectl', 'IDE', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', "#{vb_dir}/disk#{i}.vdi"]
      end
      node.vm.provision "file", source: "firstboot-node.sh", destination: "/tmp/firstboot.sh"
      node.vm.provision "file", source: "kube-modules.conf", destination: "/tmp/kube-modules.conf"
      node.vm.provision "shell", inline: <<-SHELL
        cp /tmp/firstboot.sh /root
        cp /tmp/kube-modules.conf /etc/modules-load.d/kube.conf
        reboot
      SHELL
    end
  end

end
