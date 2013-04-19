## Deploying Hadoop Clusters using Ansible.

## Preface

The Playbooks in this example are  made to deploy Hadoop Clusters for users, these playbooks can be used to:

1) Deploy a fully functional Hadoop Cluster wth HA and automatic failover.

2) Deploy a fully functional hadoop cluster with no HA.

3)  Deploy Additional nodes to scale the cluster


## Brief introduction to diffrent components of Hadoop Cluster.

Hadoop is framework that allows processing of large datasets across large clusters. The two main components that make up a Hadoop cluster are HDFS Filesystem 
and the MapReduce framework. 
Briefly HDFS filesystem is responisble for storing data across the cluster nodes on it's local disks.
While MapReduce is the jobs that would run on these nodes to get a meaningful result using the data stored on these hdfs filesystem.
  
Lets have a closer look at each of these components.

## HDFS

![Alt text](/images/hdfs.png "HDFS")

The above diagram illustrates a hdfs filesystem, The cluster consists of three DataNodes who are responsible for storing/replicating data, while the NameNode is a process which is responsible for storing the metadata for the entire Filesystem.
As the example illustrates above when a client wants to write a file to the HDFS cluster it first contacts the namenode and let's it know that it want to write a file. The namenode then decides where and how the file should be saved and notifies the client about it's decision.

In the given example "File1" has a size of 128MB and the block size of the HDFS filesystem is 64 MB, Hence the namenode instructs the client to break down the file into two diffrent blocks and write the first block to Datanode1 and the second block to Datanode2. Upon recieving the notification from NameNode the client contacts the Datanode1 and Datanode2 directly and writes the data. Once the data is recieved by the datanodes the datanodes replicates the the block cross other nodes, the number of nodes across which the data would be replicated is based on the dfs configuration, the default value is 3.
Meanwhile the NameNode updates it metadata with the entry of the new file "File1" and the locations where they are stored.  


##MapReduce

MapReduce is mostly a java application that utilizes the data stored in the hdfs filesystem to get some useful/meaningful result. The whole job/application is split into two the "Map" job and the "Reduce" Job.

Let's consider an example, In the previous step we had uploaded the "File1" into the hdfs filesystem and the file broken down into two diffrent blocks, let's consider that the first block had the data "black sheep" in it and the second block has data "white sheep" in it. Now let's assume a client want to get count of all the words occuring in "File1".
Inorder to get the count, the first thing the client would have to do is write a "map" program then a "reduce" program.
Here's a psudeo code of how the map and reduce job might look like:

		mapper (File1, file-contents):
		for each word in file-contents:
		emit (word, 1)

		reducer (word, values):
		sum = 0
		for each value in values:
		  sum = sum + value
		emit (word, sum)

The work of the mapper job is to go through all the words in the file and emit a key,value pair, in this case the key is the word itself and value is always 1.
The reducer is quite simple increment the value of sum by 1, for each value it gets.

Once the map and reduce jobs is ready the client would instruct the "JobTracker" ( The process resposible for scheduling the jobs on the cluster) to run the mapreduce job on "File1"
		
Let have closer look at the anotomy of a Map Job.
    

![Alt text](/images/map.png "Map job")

As the Figure above shows when the client instructs the jobtracker to run a job on File1, the jobtracker first contacts the namenode to determine where the blocks of the File1 are, Then the jobtracker sends down the map jobs jar file down to the nodes having the blocks and the tasktracker process in those nodes run those jar/java files.
In the above example datanode1 and datanode2 had the blocks so the tasktrackers on those nodes run the map jobs, Once the jobs are completed the two nodes would have  key,value results as below:

MapJob Results:

TaskTracker1:
 
"Black: 1"                                                                                                                                                    "Sheep: 1"

TaskTracker2:

"White: 1"                                                                                                                                                    "Sheep: 1"


Once the Map Phase is completed the jobtracker process initiates the Shuffle and Reduce process.
Let's have closer look at the shuffle-reduce job.

![Alt text](/images/reduce.png "Reduce job")

As the figure above demostrates the first thing that jobtracker does is that it spawns a reducer job on the datanode/tasktracker nodes for each "key" in the job results. In this case we have three keys "black,white,sheep" in our results, so three reducers are spawned one for each key and the map jobs shuffles/ or give out thier keys to the respective reduce jobs who owns that key. Then as per the reduce jobs code the sum is calculated and the result is written into the HDFS filesystem in a common directory. In the above example the output directory is specified as "/home/ben/oputput" so all the reducers will write thier results into this directory under diffrent files, the file names being "part-00xx", where x being the reducer/partition number.

## Hadoop Deployment. 


![Alt text](/images/hadoop.png "Reduce job")

The above diagram depicts a typical hadoop deployment, the namenode and jobtracker usually resides on the same node, though it can on seperate node. The datanodes and tasktrackers run on the same node. The size of the cluster can be scaled to thousands of node with petabytes of storage.
The above deployment model provides redundancy for data as the hdfs filesytem takes care of the data replication, The only single point of failure are the NameNode and the TaskTracker. If any of these components fail the cluster wont be usable.

## Making Hadoop HA.

To make Hadoop Cluster Highly Available we would have to add another set of Jobtracker/Namenode and make sure that the data updated by the master is also somehow also updated by the Client, and incase of the failure of the primary nodes/process the Seconday node/process takes over that role.

The First things that has be taken care is the data held/updated by the NameNode, As we recall NameNode holds all the metadata about the filesytem so any update to the metadata should also be reflected on the secondary namenode's metadata copy. 
This syncroniztion of the primary and secondary namenode metadata is handled by the Quorum Journal Manager.

###Quorum Journal Manager.


![Alt text](/images/qjm.png "QJM")

As the figure above shows the Quorum Journal manager consists of the journal manager client and journal manager nodes. The journal manager clients resides on the same node as the namenodes, and in case of primary collects all the edits logs happening on the namenode and sends it out to the Journal nodes. The journal manager client residing on the secondary namenode regurlary contacts the journal nodes and updates it's local metadata to be consistant with the master node. Incase of primary node failure the the seconday namenode updates itself to the lastest edit logs and takes over as the primary namenode.

###Zookeeper

Apart from the data consistentcy, a distrubuted/cluster system would also need mechanism for centralized co-ordination, for example there should be a way for secondary node to tell if the primary node is running properly, and if not it has to take up the act of becoming the primary.

Zookeeper provides Hadoop with a mechanism to co-ordinate with each other.

![Alt text](/images/zookeeper.png "Zookeeper")

As the figure above shows the the zookeeper services are a client server based service, The server service itself is replicated over a set of machines that comprise the service, in short HA is built inbuilt for Zookeeper servers.

For hadoop two zookeeper client have been built, zkfc (zookeeper failover controller ) for namenode and jobtracker, which runs on the same machines as the namenode/jobtracker themselves.
 
When a zkfc client is started it establishes a connection with one of the zookeeper nodes and obtians a session id. The Client then keeps a health check on the namenode/jobtracker and keeps sending heartbeats to the zookeeper.
If the zkfc client detects a failure of the namenode/jobtracker it removes itself from the zookeeper active/stanby election, and the other zkfc client fences this node/service and takes over the primary role.

## Hadoop HA Deployment.

![Alt text](/images/hadoopha.png "Hadoop_HA")

The above diagram depicts a fully HA Hadoop Cluster with no single point of Failure and automated failover.


## Deploying Hadoop Clusters with Ansible.

Setting up a hadoop cluster without HA itself can be a bit task and time consuming, and come HA things would be a bit more difficult to get the configurations and sequences proper and get the cluster up. 

Ansible can automate the whole process deploying a Hadoop Cluster with HA or without HA. (Yes, with the same playbook), and all this in matter of minutes. This can be really handy if you need to build environments frequently, or in case of disaster or node failures recovery time can be greatly reduced by automating deployments with Ansible.

let's have look how these can be done using Ansible.


## Deploying a Hadoop Cluster with HA

####Pre-requesite's

The Playbooks have been tested using Ansible v1.2, and Centos 6.x (64 bit)

Modify group_vars/all to choose the interface for hadoop communication.

Optionally you change the hadoop specific parameter like port's or directories by editing group_vars/all file.

Before launching the deployment playbook make sure the inventory file ( hosts ) have be setup properly, Here's a sample: 

		[hadoop_master_primary]
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

To deploy the mapreduce job run the following script from any of the hadoop master nodes as user 'hdfs'. The job would count the number of occurance of the word 'hello' in the given inputfile. Eg: su - hdfs -c "/tmp/job.sh"

		#!/bin/bash		
		cat > /tmp/inputfile << EOF
		hello
		sf
		sdf
		hello
		sdf
		sdf
		EOF
		hadoop fs -put /tmp/inputfile /inputfile
		hadoop jar /usr/lib/hadoop-0.20-mapreduce/hadoop-examples.jar grep /inputfile /outputfile 'hello'
		hadoop fs -get /outputfile /tmp/outputfile/

to verify the result read the file on  server located at /tmp/outputfile/part-00000, which should give you the count.

##Scale the Cluster

The Hadoop cluster when reaches it's maximum capacity it can be scaled by adding nodes, this can be easily accomplished by adding the node entry in the invetory file (hosts) under the hadoop_slaves group and running the following command.

		ansible-playbook -i hosts site.yml --tags=slaves

## Deploy a non HA Hadoop Cluster

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

and edit the group_vars/all file to disable HA:

		ha_enabled: False

and run the following command:

		ansible-playbook -i hosts site.yml 

The validity of the cluster can be checked by running the same mapreduce job that has documented above for an HA Hadoop Cluster
