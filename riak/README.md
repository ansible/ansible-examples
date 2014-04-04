#### Introduction

These example playbooks should help you get an idea of how to use the riak ansible module.  These playbooks were tested on Ubuntu Precise (12.04) and CentOS 6.4, both on x86_64.

These playbooks do not currently support selinux.

#### About Riak

Riak is distributed key-value store that is architected for:

* **Availability**: Riak replicates and retrieves data intelligently so it is available for read and write operations, even in failure conditions
* **Fault-Tolerance**: You can lose access to many nodes due to network partition or hardware failure without losing data
* **Operational Simplicity**: Add new machines to your Riak cluster easily without incurring a larger operational burden – the same ops tasks apply to small clusters as large clusters
* **Scalability**: Riak automatically distributes data around the cluster and yields a near-linear performance increase as you add capacity.

For more information, please visit [http://docs.basho.com/riak/latest/](http://docs.basho.com/riak/latest/)

#### Requirements

After checking out the ansible-examples project:

	cd ansible-examples/riak
	ansible-galaxy install -r roles.txt -p roles

This will pull down the roles that are required to run this playbook from Ansible Galaxy and place them in ansible-examples/riak/roles.  Should you have another directory you have configured for roles, specify it with the `-p` option. 

### Riak Role Documentation

Documentation for the Riak role [can be found here](https://github.com/basho/ansible-riak/blob/master/README.md). This covers all of the variables one can use with the Riak role.


#### Playbooks 

Here are the playbooks that you can use with the ansible-playbook commands:


* **setup_riak.yml** - installs riak onto nodes
* **form_cluster.yml** - forms a riak cluster
* **rolling_restart.yml** - demonstrates the ability to perform a rolling
configuration change.  Similar principals could apply to performing
rolling upgrades of Riak itself.


#### Using Vagrant

Install vagrant!


run:

	ssh-add ~/.vagrant.d/insecure_private_key
	vagrant up
	ansible-playbook -v -u vagrant setup_riak.yml -i hosts 		
	
ssh to your nodes

	vagrant ssh riak-1.local
