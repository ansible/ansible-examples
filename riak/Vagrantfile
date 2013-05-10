# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'fileutils'

Vagrant::Config.run do |config|

  # choices for virtual machines:
  #config.vm.box = 'ubuntu-1204'
  #config.vm.box_url = 'http://files.vagrantup.com/precise64.box'
  config.vm.box = 'centos-6.4'
  #config.vm.box_url = 'http://puppet-vagrant-boxes.puppetlabs.com/centos-64-x64-vbox4210-nocm.box'

  # specify all Riak VMs:
  nodes = 3
  baseip = 5
  (1..nodes).each do |n|
    ip   = "10.42.0.#{baseip + n.to_i}"
    name = "riak-#{n}.local"
    config.vm.define name do |cfg|
      cfg.vm.host_name = name
      cfg.vm.network :hostonly, ip

      # give all nodes a little bit more memory:
      cfg.vm.customize ["modifyvm", :id, "--memory", 1024, '--cpus', '1']

      #get those gems installed
     #cfg.vm.provision :shell, :path => "shellprovision/bootstrap.sh"
    end
  end


end
