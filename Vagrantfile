$script = <<-SCRIPT
n1.vm.provision "shell", inline: "[ ! -f '/home/vagrant/.ssh/id_rsa' ] && ssh-keygen -q -f /home/vagrant/.ssh/id_rsa -N ''"
n1.vm.provision "shell", inline: "cp /home/vagrant/.ssh/id_rsa.pub /vagrant/"
n2.vm.provision "file", source: "id_rsa.pub", destination: "/home/vagrant/.ssh/"
n2.vm.provision "shell", inline: "[ ! -f '/home/vagrant/.ssh/id_rsa_n1.pub' ] && cat /vagrant/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys"
n2.vm.provision "file", source: "id_rsa.pub", destination: "/home/vagrant/.ssh/id_rsa_n1.pub"
SCRIPT


VAGRANTFILE_API_VERSION = "2"
ENV['VAGRANT_SERVER_URL'] = 'http://vagrant.elab.pro'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  #config.vm.provider = 'virtualbox'
    
  #config.ssh.private_key_path = "/home/ksf/.ssh/id_rsa.pub"
  config.vm.define "net1" do | n1 |
    n1.vm.box= 'ubuntu/jammy64'
    n1.vm.host_name = "net1"
    n1.vm.network "private_network", ip: "192.168.56.5"
    
      n1.vm.provider :virtualbox do |res|

        res.customize ["modifyvm", :id, "--cpus", "2"]
        res.customize ["modifyvm", :id, "--memory", "2000"]
      end
  end

  config.vm.define "net2" do | n2 |
    n2.vm.box= 'ubuntu/jammy64'
    n2.vm.host_name = "net2"
    n2.vm.network "private_network", ip: "192.168.56.10"
    
      n2.vm.provider :virtualbox do |res|

        res.customize ["modifyvm", :id, "--cpus", "2"]
        res.customize ["modifyvm", :id, "--memory", "2000"]
      end
    n2.vm.provision "shell", inline: <<-SHELL
     sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config    
     systemctl restart sshd.service
     SHELL
  end
  
    

  config.vm.provision "ansible" do |ansible|
    
    ansible.groups = {
      "net" => ["net1", "net2"]
    }
    ansible.playbook = "playbook.yml"
    ansible.compatibility_mode = "2.0"
  end

end