##Deploying a sharded, production-ready MongoDB cluster with Ansible
------------------------------------------------------------------------------

- Requires Ansible 1.2
- Expects CentOS/RHEL 6 hosts

### A Primer
---------------------------------------------

![Alt text](images/nosql_primer.png "Primer NoSQL")

The above diagram shows how MongoDB differs from the traditional relational
database model. In an RDBMS, the data associated with 'user' is stored in a
table, and the records of users are stored in rows and columns. In MongoDB, the
'table' is replaced by a 'collection' and the individual 'records' are called
'documents'.  One thing to notice is that the data is stored as key/value pairs
in BJSON format.

Another thing to notice is that NoSQL-style databases have a looser consistency
model. As an example, the second document in the users collection has an
additonal field of 'last name'.
 
### Data Replication
------------------------------------

![Alt text](images/replica_set.png "Replica Set")

Data backup is achieved in MongoDB via _replica sets_. As the figure above shows,
a single replication set consists of a replication master (active) and several
other replications slaves (passive). All the database operations like
add/delete/update happen on the replication master and the master replicates
the data to the slave nodes. _mongod_ is the process which is resposible for all
the database activities as well as replication processes. The minimum
recommended number of slave servers are 3.

### Sharding (Horizontal Scaling) .
------------------------------------------------

![Alt text](images/sharding.png "Sharding")

Sharding works by partitioning the data into seperate chunks and allocating
diffent ranges of chunks to diffrent shard servers. The figure above shows a
collection which has 90 documents which have been sharded across the three
servers: the first shard getting ranges from 1-29, and so on. When a client wants
to access a certain document, it contacts the query router (mongos process),
which in turn contacts the 'configuration node', a lightweight mongod
process) that keeps a record of which ranges of chunks are distributed across
which shards. 

Please do note that every shard server should be backed by a replica set, so
that when data is written/queried copies of the data are available. So in a
three-shard deployment we would require 3 replica sets and primaries of each
would act as the sharding server.

Here are the basic steps of how sharding works:

1) A new database is created, and collections are added.

2) New documents get updated when clients update, and all the new documents
goes into a single shard.

3) When the size of collection in a shard exceeds the 'chunk_size' the
collection is split and balanced across shards.


### Deploying MongoDB Ansible
--------------------------------------------

#### Deploy the Cluster
----------------------------

![Alt text](images/site.png "Site")
  
The diagram above illustrates the deployment model for a MongoDB cluster deployed by
Ansible. This deployment model focuses on deploying three shard servers,
each having a replica set, with the backup replica servers serving as the other two shard
primaries. The configuration servers are co-located with the shards. The _mongos_
servers are best deployed on seperate servers. This is the minimum recomended
configuration for a production-grade MongoDB deployment. Please note that the
playbooks are capable of deploying N node clusters, not limited to three. Also,
all the processes are secured using keyfiles.

#### Prerequisite

Edit the group_vars/all file to reflect the below variables.

1) iface: 'eth1'     # the interface to be used for all communication.
		
2) Set a unique mongod_port variable in the inventory file for each MongoDB
server.

3) The default directory for storing data is /data, please do change it if
required. Make sure it has sufficient space: 10G is recommended.

### Deployment Example

The inventory file looks as follows:

		#The site wide list of mongodb servers
		[mongo_servers]
		mongo1 mongod_port=2700
		mongo2 mongod_port=2701
		mongo3 mongod_port=2702

		#The list of servers where replication should happen, including the master server.
		[replication_servers]
		mongo3
		mongo1
		mongo2

		#The list of mongodb configuration servers, make sure it is 1 or 3
		[mongoc_servers]
		mongo1
		mongo2
		mongo3

		#The list of servers where mongos servers would run. 
		[mongos_servers]
		mongos1
		mongos2

Build the site with the following command:

		ansible-playbook -i hosts site.yml


#### Verifying the Deployment 
---------------------------------------------

Once configuration and deployment has completed we can check replication set
availability by connecting to individual primary replication set nodes, `mongo
--host 192.168.1.1 --port 2700` and issue the command to query the status of
replication set, we should get a similar output.

		
		web2:PRIMARY> rs.status()
		{
			"set" : "web2",
			"date" : ISODate("2013-03-19T10:26:35Z"),
			"myState" : 1,
			"members" : [
			{
				"_id" : 0,
				"name" : "web2:2013",
				"health" : 1,
				"state" : 1,
				"stateStr" : "PRIMARY",
				"uptime" : 102,
				"optime" : Timestamp(1363688755000, 1),
				"optimeDate" : ISODate("2013-03-19T10:25:55Z"),
				"self" : true
			},
			{
				"_id" : 1,
				"name" : "web3:2013",
				"health" : 1,
				"state" : 2,
				"stateStr" : "SECONDARY",
				"uptime" : 40,
				"optime" : Timestamp(1363688755000, 1),
				"optimeDate" : ISODate("2013-03-19T10:25:55Z"),
				"lastHeartbeat" : ISODate("2013-03-19T10:26:33Z"),
				"pingMs" : 1
			}
			],
			"ok" : 1
		}


We can check the status of the shards as follows: connect to the mongos service
'mongo localhost:8888/admin -u admin -p 123456' and issue the following command to get
the status of the Shards:


		 
		mongos> sh.status()
		--- Sharding Status --- 
		  sharding version: { "_id" : 1, "version" : 3 }
		  shards:
			{  "_id" : "web2",  "host" : "web2/web2:2013,web3:2013" }
			{  "_id" : "web3",  "host" : "web3/web2:2014,web3:2014" }
  		databases:
			{  "_id" : "admin",  "partitioned" : false,  "primary" : "config" }


We can also make sure the sharding works by creating a database, a collection,
and populate it with documents and check if the chunks of the collection are
balanced equally across nodes. The below diagram illustrates the verification
step.

-------------------------------------------------------------------------------------------------------------------------------------------------------------

![Alt text](images/check.png "check")

The above mentioned steps can be tested with an automated playbook.

Issue the following command to run the test. Pass one of the _mongos_ servers
in the _servername_ variable.
		
		ansible-playbook -i hosts playbooks/testsharding.yml -e servername=server1


Once the playbook completes, we check if the sharding has succeeded by logging
on to any mongos server and issuing the following command. The output displays
the number of chunks spread across the shards.

		mongos> sh.status()
			--- Sharding Status --- 
  			sharding version: { "_id" : 1, "version" : 3 }
  			shards:
			{  "_id" : "bensible",  "host" : "bensible/bensible:20103,web2:20103,web3:20103" }
			{  "_id" : "web2",  "host" : "web2/bensible:20105,web2:20105,web3:20105" }
			{  "_id" : "web3",  "host" : "web3/bensible:20102,web2:20102,web3:20102" }
  			databases:
			{  "_id" : "admin",  "partitioned" : false,  "primary" : "config" }
			{  "_id" : "test",  "partitioned" : true,  "primary" : "web3" }
			
				test.test_collection chunks:
				
				bensible	7
				web2	6
				web3	7
			
			

 
### Scaling the Cluster
---------------------------------------

![Alt text](images/scale.png "scale")

To add a new node to the existing MongoDB Cluster, modify the inventory file as follows:

		#The site wide list of mongodb servers
		[mongoservers]
		mongo1 mongod_port=2700
		mongo2 mongod_port=2701
		mongo3 mongod_port=2702
		mongo4 mongod_port=2703

		#The list of servers where replication should happen, make sure the new node is listed here.
		[replicationservers]
		mongo4
		mongo3
		mongo1
		mongo2

		#The list of mongodb configuration servers, make sure it is 1 or 3
		[mongoc_servers]
		mongo1
		mongo2
		mongo3

		#The list of servers where mongos servers would run. 
		[mongos_servers]
		mongos1
		mongos2

Make sure you have the new node added in the _replicationservers_ section and
execute the following command:

		ansible-playbook -i hosts site.yml

###Verification.
-----------------------------

The newly added node can be easily verified by checking the sharding status and
seeing the chunks being rebalanced to the newly added node.

			$/usr/bin/mongo localhost:8888/admin -u admin -p 123456
			mongos> sh.status()
				--- Sharding Status --- 
  				sharding version: { "_id" : 1, "version" : 3 }
  			shards:
			{  "_id" : "bensible",  "host" : "bensible/bensible:20103,web2:20103,web3:20103" }
			{  "_id" : "web2",  "host" : "web2/bensible:20105,web2:20105,web3:20105" }
			{  "_id" : "web3",  "host" : "web3/bensible:20102,web2:20102,web3:20102" }
			{  "_id" : "web4",  "host" : "web4/bensible:20101,web3:20101,web4:20101" }
  			databases:
			{  "_id" : "admin",  "partitioned" : false,  "primary" : "config" }
			{  "_id" : "test",  "partitioned" : true,  "primary" : "bensible" }
		
			test.test_collection chunks:
			
				web4	3
				web3	6
				web2	6
				bensible	5

    
