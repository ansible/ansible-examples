#!/usr/bin/env bash
# install ansible from RPM for a CentOS/RHEL server

# install the EPEL software repository
sudo rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm

# install the epel-release RPM
sudo yum -y install ansible
# OR, install the github head and run from the dev branch
#sudo yum -y install git
#sudo git clone git://github.com/ansible/ansible.git
#sudo cd ./ansible
#sudo source ./hacking/env-setup

# create a key pair for communicating with the other servers
# RSA type key, stored in .ssh/id_rsa with an empty passphrase
#       ssh-keygen -q -t rsa -f .ssh/id_rsa -N ""
# Instead, I am using a known key pair that we can share with the servers from vagrant's home directory
sudo -u vagrant -g vagrant cp /vagrant/keys/orchestration.pri .ssh/id_rsa
sudo chmod 600 .ssh/id_rsa
sudo -u vagrant -g vagrant cp /vagrant/keys/orchestration.pub .ssh/id_rsa.pub
sudo chmod 600 .ssh/id_rsa.pub

# augment the /etc/hosts file so we can operate without a DNS service
# add the FQDNs to the /etc/hosts file, so we can operate without a DNS service
# This is more for the managing state of the systems (as we have this line also in the worker's bootstrap)
# You can operate without a /etc/hosts file by using host variables in the inventory file, which we do too.
sudo cat /vagrant/data/etc.hosts.file >> /etc/hosts

# create the .ssh/known_hosts file so we can drive automation from the orchestration node
hosts=( $(cat /vagrant/data/hosts.helper.file) )
# use ssh-keyscan to populate your "known_hosts" file first: 
# Need to group the keyscan and append operators so that .ssh/known_hosts is owned by 'vagrant'
# this didn't work sudo -u vagrant -g vagrant ssh-keyscan ${hosts[@]}  >> .ssh/known_hosts 
sudo ssh-keyscan ${hosts[@]}  >> .ssh/known_hosts 
sudo chown vagrant .ssh/known_hosts
sudo chgrp vagrant .ssh/known_hosts
sudo chmod 600 .ssh/known_hosts

# the shared folder /vagrant doesn't provide the right permissions, so get the 
# inventory file and set the correct permissions
sudo whoami 2>&1 >> shell_provisioner_ran_as
sudo -u vagrant -g vagrant cp /vagrant/data/inventory.file inventory
sudo chmod 660 inventory

# set up a user ansible configuration to set up logging by default
sudo -u vagrant -g vagrant cp /vagrant/ansible.cfg ansible.cfg
sudo chmod 664 ansible.cfg

# see if you get the right stuff
su -l vagrant -c 'ansible all -i inventory -m ping -v'
su -l vagrant -c 'ansible all -i inventory -m setup >> pre_environment.vars'
# provide some direct feedback on the multi-VM system we have provisioned
su -l vagrant -c "ansible all -i inventory -m shell -a 'grep DISTRIB_RELEASE /etc/lsb-release'"
su -l vagrant -c "ansible all -i inventory -m setup -a 'filter=ansible_memtotal_mb' "

# now let's use ansible to orchestrate the multi-tier infrastructure
# first, copy the website's configuration files to the ansible-head node
sudo -u vagrant -g vagrant mkdir files
sudo -u vagrant -g vagrant cp /vagrant/files/website-name files/website-name
sudo -u vagrant -g vagrant cp /vagrant/ubuntu-apache2.yaml .
sudo chmod 664 ubuntu-apache2.yaml
# fire up the webserver playbook. do this if you do not set up the proxy
# if you set up the proxy, you need to run both webserver and proxy together
# so that the proxy playbook can get the information from the webserver playbook
# in particular ansible_eth1 and from it the IP address is required.
#sudo -u vagrant -g vagrant ansible-playbook -i inventory ubuntu-apache2.yaml
# second, copy the load balancer configuration files to the ansible-head node
sudo -u vagrant -g vagrant mkdir templates
sudo -u vagrant -g vagrant cp /vagrant/files/haproxy.cfg.j2 templates/haproxy.cfg.j2
sudo chmod 664 templates/haproxy.cfg.j2
sudo -u vagrant -g vagrant cp /vagrant/ubuntu-haproxy.yaml .
sudo chmod 664 ubuntu-haproxy.yaml
# fire up the proxy playbook
su -l vagrant -c 'ansible-playbook -i inventory ubuntu-apache2.yaml ubuntu-haproxy.yaml'
