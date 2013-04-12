## Deploying Hadoop Clusters using Ansible.
-------------------------------------------------- 

### Preface

The Playbooks in this example are  made to deploy Hadoop Clusters for users, these playbooks can be used to:

1) Deploy a fully functional Hadoop Cluster wth HA and automatic failover.

2) Deploy a fully functional hadoop cluster with no HA.

3)  Deploy Additional nodes to scale the cluster

4) Verify the cluster by deploying MapReduce jobs

### Brief introduction to diffrent components of Hadoop Cluster.

The following diagram depicts a Hadoop Cluster with HA and automated failover which would be deployed by the Ansible Playbooks.


The two major categories of machines roles in a Hadoop cluster are Hadoop Masters and Hadoop Slaves.

#####The Hadoop masters consists of:
    
####NameNode:      

The NameNode is the centerpiece of an HDFS file system. It keeps the directory tree of all files in the file system, and tracks where across the cluster the file data is kept. It does not store the data of these files itself. Client applications talk to the NameNode whenever they wish to locate a file, or when they want to add/copy/move/delete a file. The NameNode responds the successful requests by returning a list of relevant DataNode servers where the data lives.

####JobTracker:

The JobTracker is the service within Hadoop that gives out MapReduce tasks to specific nodes in the cluster, Applications submit jobs to the Job tracker and JobTracker talks to the NameNode to determine the location of the data , once located the JobTracker submits the work to the chosen TaskTracker nodes.

#####The Hadoop Slaves consists of:

####DataNode:  

A DataNode is responsible for storing data in the HadoopFileSystem. A functional hdfs filesystem has more than one DataNode, and data is replicated across them.

####TaskTracker:  

A TaskTracker is a node in the cluster that accepts tasks - Map, Reduce and Shuffle operations from a JobTracker.


#####The Hadoop Master processes does not have high availability built into them as thier counterparts (datanode, tasktracker). Inorder to have HA for the NameNode and Jobtracker we have the following processes.

####Quorum Journal Nodes:    

The journal nodes are responsible for maintaining a journal of any modifications made to the HDFS namespace, The active namenode logs any modifications to the jounal nodes and the standby namenode reads the changes from the journal nodes and applies it to it's local namespace. In a production environment the mininum recommended number of journal nodes is 3, these nodes can also be colocated with namenode/Jobtracker.

####Zookeeper Nodes:    

The purpose of Zookeepr is cluster management, Do remember that Hadoop HA is an active/passive cluster so the cluster requires stuff's like hearbeats, locks, leader election, quorum etc.. these service are provided by the zookeeper services. The recommended number for a production use is 3.

####zkfc namenode: 

zkfc (zookeeper failover controller) is a zookeeper client application that runs on each namenode server, it's responsibilites include health monitoring, zookeeper session management, leader election etc.. i,e incase of a namenode failure the zkfc process running on that machine detects the failure and informs the zookeeper as a result of which re-election takes place and a new active namenode is selected.

####zkfc JobTracker: 

The zkfc Tasktracker performs the same functionalities as that of zkfc namenode, the diffrence being the process that zkfc is resposible for is the jobtracker 


### Deploying a Hadoop Cluster with HA

####Pre-requesite's

The Playbooks have been tested using Ansible v1.2, and Centos 6.x (64 bit)

Modify group_vars/all to choose the interface for hadoop communication.

Optionally you change the hadoop specific parameter like port's or directories by editing hadoop_vars/hadoop file.

Before launching the deployment playbook make sure the inventory file ( hosts ) have be setup properly, Here's a sample: 

		[hadoop_master_primary]15yy
		zhadoop1

		[hadoop_master_secondary]
		zhadoop2

		[hadoop_masters:children]
		hadoop_master_primary
		hadoop_master_secondary

		[hadoop_slaves]
		hadoop1
		hadoop2
		hadoop3

		[qjournal_servers]
		zhadoop1
		zhadoop2
		zhadoop3

		[zookeeper_servers]
		zhadoop1 zoo_id=1
		zhadoop2 zoo_id=2
		zhadoop3 zoo_id=3 

Once the inventory is setup the Hadoop cluster can be setup using the following command

		ansible-playbook -i hosts site.yml

Once deployed we can check the cluster sanity in difrent ways, to check the status of the hdfs filesystem and a report on all the datanodes login as hdfs useron any hadoop master servers, and issue the following command to get the report.

		hadoop dfsadmin -report

To check the sanity of HA, first login as hdfs user on any hadoop master server and get the current active/standby namenode servers.

		-bash-4.1$ hdfs haadmin -getServiceState zhadoop1
			active
		-bash-4.1$ hdfs haadmin -getServiceState zhadoop2
			standby

To get the state of the Jobtracker process login as mapred user in any hadoop master server and issue the following command:

		-bash-4.1$ hadoop mrhaadmin -getServiceState hadoop1
			standby
		-bash-4.1$ hadoop mrhaadmin -getServiceState hadoop2
			active

Once the active and the standby has been detected kill the namenode/jobtracker process in the server listed as active and issue the same commands as above 
and you should get a result where the standby has been promoted to the active state. Later you can start the killed process and see those processes listed as the passive processes.

### Running a mapreduce job on the cluster.

To run a mapreduce job on the cluster a sample playbook has been written, this playbook runs a job on the cluster which counts the occurance of the word 'hello' on an inputfile. A sample inputfile file has been created in the playbooks/inputfile file, modify the file to match your testing.
To deploy the mapreduce job run the following command.( Below -e server=<any of your hadoop master server> 

		ansible-playbook -i hosts playbooks/job.yml -e server=zhadoop1

to verify the result read the file on your ansible server located at /tmp/zhadoop1/tmp/outputfile/part-00000, which should give you the count.

###Scale the Cluster

The Hadoop cluster when reaches it's maximum capacity it can be scaled by adding nodes, this can be easily accomplished by adding the node entry in the invetory file (hosts) under the hadoop_slaves group and running the following command.

		ansible-playbook -i hosts site.yml --tags=slaves

### Deploy a non HA Hadoop Cluster

The following diagram illustrates a standalone hadoop cluster.

To deploy this cluster fill in the inventory file as follows: 

		[hadoop_master_primary]
		zhadoop1

		[hadoop_master_secondary]

		[hadoop_masters:children]
		hadoop_master_primary
		hadoop_master_secondary

		[hadoop_slaves]
		hadoop1
		hadoop2
		hadoop3

and issue the following command:

		ansible-playbook -i hosts site.yml -e ha_disabled=true --tags=no_ha

The validity of the cluster can be checked by running the same mapreduce job that has documented above for an HA Hadoop Cluster
