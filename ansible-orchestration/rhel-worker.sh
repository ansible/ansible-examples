#!/usr/bin/env bash

# installing a known key pair that we can share with the servers from vagrant's home directory
# no need to run sudo as 'vagrant' because vagrant has already properly set up authorized_keys file ownership 
sudo cat /vagrant/keys/orchestration.pub >> .ssh/authorized_keys

# add the FQNs to the /etc/hosts file, so we can operate without a DNS service
sudo cat /vagrant/data/etc.hosts.file >> /etc/hosts

