# Deploying Hadoop Clusters using Ansible

## Preface

The playbooks in this example are designed to deploy a Hadoop cluster on a
CentOS 6 or RHEL 6 environment using Ansible. The playbooks can:

1) Deploy a fully functional Hadoop cluster with HA and automatic failover.

2) Deploy a fully functional Hadoop cluster with no HA.

3) Deploy additional nodes to scale the cluster

These playbooks require Ansible 1.2, CentOS 6 or RHEL 6 target machines, and install
the open-source Cloudera Hadoop Distribution (CDH) version 4.

## Hadoop Components

Hadoop is framework that allows processing of large datasets across large
clusters. The two main components that make up a Hadoop cluster are the HDFS
Filesystem and the MapReduce framework. Briefly, the HDFS filesystem is responsible 
for storing data across the cluster nodes on its local disks. The MapReduce
jobs are the tasks that would run on these nodes to get a meaningful result
using the data stored on the HDFS filesystem.
  
Let's have a closer look at each of these components.

## HDFS

![Alt text](/images/hdfs.png "HDFS")

The above diagram illustrates an HDFS filesystem. The cluster consists of three
DataNodes which are responsible for storing/replicating data, while the NameNode
is a process which is responsible for storing the metadata for the entire
filesystem. As the example illustrates above, when a client wants to write a
file to the HDFS cluster it first contacts the NameNode and lets it know that
it want to write a file. The NameNode then decides where and how the file
should be saved and notifies the client about its decision.

In the given example "File1" has a size of 128MB and the block size of the HDFS
filesystem is 64 MB. Hence, the NameNode instructs the client to break down the
file into two different blocks and write the first block to DataNode 1 and the
second block to DataNode 2. Upon receiving the notification from the NameNode,
the client contacts DataNode 1 and DataNode 2 directly to write the data.

Once the data is recieved by the DataNodes, they replicate the block across the
other nodes. The number of nodes across which the data would be replicated is
based on the HDFS configuration, the default value being 3. Meanwhile the
NameNode updates its metadata with the entry of the new file "File1" and the
locations where the parts are stored.

## MapReduce

MapReduce is a Java application that utilizes the data stored in the
HDFS filesystem to get some useful and meaningful result. The whole job is
split into two parts: the "Map" job and the "Reduce" Job.

Let's consider an example. In the previous step we had uploaded the "File1"
into the HDFS filesystem and the file was broken down into two different
blocks.  Let's assume that the first block had the data "black sheep" in it and
the second block has the data "white sheep" in it. Now let's assume a client
wants to get count of all the words occurring in "File1". In order to get the
count, the first thing the client would have to do is write a "Map" program
then a "Reduce" program.

Here's a psudeo code of how the Map and Reduce jobs might look:

		mapper (File1, file-contents):
		for each word in file-contents:
		emit (word, 1)

		reducer (word, values):
		sum = 0
		for each value in values:
		  sum = sum + value
		emit (word, sum)

The work of the Map job is to go through all the words in the file and emit
a key/value pair. In this case the key is the word itself and value is always
1.

The Reduce job is quite simple: it increments the value of sum by 1, for each
value it gets.

Once the Map and Reduce jobs are ready, the client would instruct the
"JobTracker" (the process resposible for scheduling the jobs on the cluster)
to run the MapReduce job on "File1"
		
Let's have closer look at the anotomy of a Map job.
    

![Alt text](/images/map.png "Map job")

As the figure above shows, when the client instructs the JobTracker to run a
job on File1, the JobTracker first contacts the NameNode to determine where the
blocks of the File1 are. Then the JobTracker sends the Map job's JAR file down
to the nodes having the blocks, and the TaskTracker process those nodes to run
the application.

In the above example, DataNode 1 and DataNode 2 havw the blocks, so the
TaskTrackers on those nodes run the Map jobs. Once the jobs are completed the
two nodes would have key/value results as below:

MapJob Results:

		TaskTracker1:
		"Black: 1"
		"Sheep: 1"

		TaskTracker2:
		"White: 1"
		"Sheep: 1"


Once the Map phase is completed the JobTracker process initiates the Shuffle
and Reduce process.

Let's have closer look at the Shuffle-Reduce job.

![Alt text](/images/reduce.png "Reduce job")

As the figure above demonstrates, the first thing that the JobTracker does is
spawn a Reducer job on the DataNode/Tasktracker nodes for each "key" in the job
result. In this case we have three keys: "black, white, sheep" in our result,
so three Reducers are spawned: one for each key. The Map jobs shuffle the keys
out to the respective Reduce jobs. Then the Reduce job code runs and the sum is
calculated, and the result is written into the HDFS filesystem in a common
directory. In the above example the output directory is specified as
"/home/ben/output" so all the Reducers will write their results into this
directory under different filenames; the file names being "part-00xx", where x
is the Reducer/partition number.


## Hadoop Deployment

![Alt text](/images/hadoop.png "Reduce job")

The above diagram depicts a typical Hadoop deployment. The NameNode and
JobTracker usually reside on the same machine, though they can run on seperate
machines. The DataNodes and TaskTrackers run on the same node. The size of the
cluster can be scaled to thousands of nodes with petabytes of storage.

The above deployment model provides redundancy for data as the HDFS filesytem
takes care of the data replication. The only single point of failure are the
NameNode and the JobTracker. If any of these components fail the cluster will
not be usable.


## Making Hadoop HA

To make the Hadoop cluster highly available we would have to add another set of
JobTracker/NameNodes, and make sure that the data updated by the master is also
somehow also updated by the client. In case of failure of the primary node, the
secondary node takes over that role.

The first thing that has to be dealt with is the data held by the NameNode. As
we recall, the NameNode holds all of the metadata about the filesystem, so any
update to the metadata should also be reflected on the secondary NameNode's
metadata copy. The synchronization of the primary and seconary NameNode
metadata is handled by the Quorum Journal Manager.


### Quorum Journal Manager

![Alt text](/images/qjm.png "QJM")

As the figure above shows the Quorum Journal manager consists of the journal
manager client and journal manager nodes. The journal manager clients reside
on the same node as the NameNodes, and in case of primary node, collects all the
edits logs happening on the NameNode and sends it out to the Journal nodes. The
journal manager client residing on the secondary namenode regurlary contacts
the journal nodes and updates its local metadata to be consistant with the
master node. In case of primary node failure the secondary NameNode updates
itself to the latest edit logs and takes over as the primary NameNode.


### Zookeeper

Apart from data consistency, a distributed cluster system also needs a
mechanism for centralized coordination. For example, there should be a way for
the secondary node to tell if the primary node is running properly, and if not
it has to take up the role of the primary. Zookeeper provides Hadoop with a
mechanism to coordinate in this way.

![Alt text](/images/zookeeper.png "Zookeeper")

As the figure above shows, the Zookeeper services are client/server baseds
service. The server component itself is replicated over a set of machines that
comprise the service. In short, high availability is built into the Zookeeper
servers.

For Hadoop, two Zookeeper clients have been built: ZKFC (Zookeeper Failover
Controller), one for the NameNode and one for JobTracker. These clients run on
the same machines as the NameNode/JobTrackers themselves.

When a ZKFC client is started, it establishes a connection with one of the
Zookeeper nodes and obtains a session ID. The client then keeps a health check
on the NameNode/JobTracker and sends heartbeats to the ZooKeeper.

If the ZKFC client detects a failure of the NameNode/JobTracker, it removes
itself from the ZooKeeper active/standby election, and the other ZKFC client
fences the node/service and takes over the primary role.


## Hadoop HA Deployment

![Alt text](/images/hadoopha.png "Hadoop_HA")

The above diagram depicts a fully HA Hadoop Cluster with no single point of
failure and automated failover.


## Deploying Hadoop Clusters with Ansible

Setting up a Hadoop cluster without HA itself can be a challenging and
time-consuming task, and with HA, things become even more difficult.

Ansible can automate the whole process of deploying a Hadoop cluster with or
without HA with the same playbook, in a matter of minutes. This can be used for
quick environment rebuild, or in case of disaster or node failures, recovery
time can be greatly reduced with Ansible automation.

Let's have a look to see how this is done.

## Deploying a Hadoop cluster with HA

### Prerequisites

These playbooks have been tested using Ansible v1.2, and CentOS 6.x (64 bit)

Modify group_vars/all to choose the network interface for Hadoop communication.

Optionally you change the Hadoop-specific parameters like ports or directories
by editing group_vars/all file.

Before launching the deployment playbook make sure the inventory file (hosts)
is set up properly. Here's a sample: 

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

Once the inventory is set up, the Hadoop cluster can be setup using the following
command

		ansible-playbook -i hosts site.yml

Once deployed, we can check the cluster sanity in different ways. To check the
status of the HDFS filesystem and a report on all the DataNodes, log in as the
'hdfs' user on any Hadoop master server, and issue the following command to get
the report:

		hadoop dfsadmin -report

To check the sanity of HA, first log in as the 'hdfs' user on any Hadoop master
server and get the current active/standby NameNode servers this way:

		-bash-4.1$ hdfs haadmin -getServiceState zhadoop1
			active
		-bash-4.1$ hdfs haadmin -getServiceState zhadoop2
			standby

To get the state of the JobTracker process login as the 'mapred' user on any
Hadoop master server and issue the following command:

		-bash-4.1$ hadoop mrhaadmin -getServiceState hadoop1
			standby
		-bash-4.1$ hadoop mrhaadmin -getServiceState hadoop2
			active

Once you have determined which server is active and which is standby, you can
kill the NameNode/JobTracker process on the server listed as active and issue
the same commands again, and you should see that the standby has been promoted
to the active state. Later, you can restart the killed process and see that node
listed as standby.

### Running a MapReduce Job

To deploy the mapreduce job run the following script from any of the hadoop
master nodes as user 'hdfs'. The job would count the number of occurance of the
word 'hello' in the given inputfile. Eg: su - hdfs -c "/tmp/job.sh"

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

To verify the result, read the file on the server located at
/tmp/outputfile/part-00000, which should give you the count.

## Scale the Cluster

When the Hadoop cluster reaches its maximum capacity, it can be scaled by
adding nodes.  This can be easily accomplished by adding the node hostname to
the Ansible inventory under the hadoop_slaves group, and running the following
command:

		ansible-playbook -i hosts site.yml --tags=slaves

## Deploy a non-HA Hadoop Cluster

The following diagram illustrates a standalone Hadoop cluster.

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

Edit the group_vars/all file to disable HA:

		ha_enabled: False

And run the following command:

		ansible-playbook -i hosts site.yml 

The validity of the cluster can be checked by running the same MapReduce job
that has documented above for an HA Hadoop cluster.

