vb_dir = "#{ENV['HOME']}/VirtualBox\ VMs"
nodes = 3
disk_size = 4096

Vagrant.configure("2") do |config|

  config.vm.box = "centos/7"
  config.vm.box_check_update = true
  config.vm.provision "shell", inline: <<-SHELL
    setenforce 0
    sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config
    sed -i /swap/d /etc/fstab
    sed -i s/enabled=1/enabled=0/ /etc/yum/pluginconf.d/fastestmirror.conf
    #modprobe br_netfilter
    mkdir /root/.ssh
    cp /vagrant/sysctl.conf /vagrant/hosts /etc
    cp /vagrant/*.repo /etc/yum.repos.d
    cp /vagrant/firstboot.service /etc/systemd/system
    cp /vagrant/id_rsa /root/.ssh
    cp /vagrant/id_rsa.pub /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/id_rsa
    systemctl enable firstboot
  SHELL

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
  end

  config.vm.define "master" do |master|
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: "192.168.99.99", virtualbox__intnet: true
    master.vm.provider :virtualbox do |vb| 
      vb.customize ["modifyvm", :id, "--name", "master"]
      vb.memory = 2048
    end
    master.vm.provision "shell", inline: <<-SHELL
      cp /vagrant/firstboot-master.sh /root/firstboot.sh
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
      node.vm.provision "shell", inline: <<-SHELL
        cp /vagrant/firstboot-node.sh /root/firstboot.sh
        cp /vagrant/kube-modules.conf /etc/modules-load.d/kube.conf
        reboot
      SHELL
    end
  end

end
