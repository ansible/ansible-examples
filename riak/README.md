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

This playbook requires ansible 1.2.

#### Hosts File Naming Conventions

In the hosts file, we use a host variable **node_type** to ease the cluster joining process.  The following values of **node_type** can be used.

* **primary** - all nodes attempt to join this node.
* **last** - this node plans and commits changes to the cluster, in this example, the joining of the nodes.  
* **middle** - all nodes in between **primary** and **last**

### group_vars ###

All sorts of configuration settings can be tuned in group_vars/all.  Here's a breakdown.

* **firewall**: **True**  - whether you'd like to enabled iptables for the configuration
* riak:
	* **version**: *1.3.1*  - the version of the package you want to install.  For Debian/Ubuntu distributions it needs to contain the distro. For example: *1.3.1~precise1*
	* **iface**: *eth1* - the interface Riak will be listening on
    * **handoff_port**: *8099* - the port used for handoffs
    * **http_port**: *8098* - the port used for Riak's rest interface.
    * **pb_port**: *8087* - the port used for Riak's protocol buffers interface.
    * **mountpoint**: */var/lib/riak* - the mount point where the riak data partition lives.
    * **partition**: */dev/mapper/VolGroup-lv_riak* - the partition where riak is mounted
    * **physical_disk**: *sda*  - the physical disk that is associated with the partition riak is mounted
    * **scheduler**: *noop* - the I/O scheduler you want to use
    * **backend**: *bitcask* - the Riak backend you want to use
    * **ring_size**: *64*  - the number of vnodes in the distributed ring
    * **log_rotate**: *4* - how often log rotated should occur.
 
There is no concept of node roles in Riak proper, it is master-less.

You can build an entire cluster by first modifying the hosts file to fit your
network.

#### Using the Playbooks

Here are the playbooks that you can use with the ansible-playbook commands:

* **site.yml** - creates a complete riak cluster, it calls setup_riak.yml and form_cluster.yml
* **setup_riak.yml** - installs riak onto nodes
* **form_cluster.yml** - forms a riak cluster
* **rolling_restart.yml** - demonstrates the ability to perform a rolling
configuration change.  Similar principals could apply to performing
rolling upgrades of Riak itself.


#### Using Vagrant

Install vagrant!

First choose an OS in your Vagrantfile.

run:

	vagrant up
	
launch the playbook, when prompted for password, enter "vagrant"

	ansible-playbook -v   -u vagrant site.yml -i hosts -k	
	
ssh to your nodes

	vagrant ssh riak-1.local
