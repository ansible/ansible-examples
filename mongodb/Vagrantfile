# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  config.vm.box = "bento/centos-7.1"
    
  # Primary data centre
  config.vm.define "mongo_dc1_1" do |server|
    server.vm.network :forwarded_port, host: 27017, guest: 27017
    server.vm.network :forwarded_port, host: 27018, guest: 22
    server.vm.network "private_network", ip: "10.0.0.101", :netmask => "255.255.0.0"
    server.vm.hostname = "mongo1"
  end

  config.vm.define "mongo_dc1_2" do |server|
    server.vm.network :forwarded_port, host: 27019, guest: 27017
    server.vm.network :forwarded_port, host: 27020, guest: 22
    server.vm.network "private_network", ip: "10.0.0.102", :netmask => "255.255.0.0"
    server.vm.hostname = "mongo2"
  end

  config.vm.define "mongo_dc2_1" do |server|
    server.vm.network :forwarded_port, host: 27021, guest: 27017
    server.vm.network :forwarded_port, host: 27022, guest: 22
    server.vm.network "private_network", ip: "10.0.0.103", :netmask => "255.255.0.0"
    server.vm.hostname = "mongo3"
  end

  config.vm.provision :shell, inline: "systemctl start firewalld"

  config.vm.provider "virtualbox" do |v|
    v.gui = false
    memory = "1024"
  end
end
