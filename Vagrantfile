Vagrant.configure("2") do |config|

  config.vm.box = "centos/7"

  config.vm.network :private_network, ip: "192.168.33.10"
  config.vm.network "forwarded_port", guest: 8500, host: 8500
  config.vm.network "forwarded_port", guest: 4646, host: 4646
  config.vm.network "forwarded_port", guest: 3000, host: 3000
  config.vm.network "forwarded_port", guest: 3001, host: 3001
  config.vm.network "forwarded_port", guest: 9000, host: 9000
  config.vm.network "forwarded_port", guest: 9001, host: 9001
  config.vm.network "forwarded_port", guest: 19000, host: 19000
  config.vm.network "forwarded_port", guest: 19001, host: 19001

  config.vm.synced_folder "./", "/home/vagrant/app",create:"true"

  config.vm.provision "shell", inline: <<-SHELL
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum makecache fast
    sudo yum install -y docker-ce unzip
    sudo systemctl enable docker-ce
    sudo systemctl start docker-ce
    sudo curl -L https://github.com/docker/compose/releases/download/1.25.0/docker-compose-`uname -s`-`uname -m` > docker-compose
    sudo mv docker-compose /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo gpasswd -a vagrant docker
    sudo systemctl restart docker
    sudo curl -L https://releases.hashicorp.com/consul/1.6.2/consul_1.6.2_linux_amd64.zip -o /tmp/consul.zip
    sudo unzip  -d /usr/local/bin/ /tmp/consul.zip
    sudo curl -L https://releases.hashicorp.com/nomad/0.10.1/nomad_0.10.1_linux_amd64.zip -o /tmp/nomad.zip
    sudo unzip  -d /usr/local/bin/ /tmp/nomad.zip
  SHELL
end