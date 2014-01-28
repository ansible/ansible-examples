# Deploying a Highly Available production ready OpenShift Deployment 

- Requires Ansible 1.3
- Expects CentOS/RHEL 6 hosts (64 bit)
- RHEL 6 requires rhel-x86_64-server-optional-6 in enabled channels


## A Primer into OpenShift Architecture

###OpenShift Overview

OpenShift Origin is  the next generation application hosting platform which enables the users to create, deploy and manage applications within their cloud. In other words, it provides a PaaS service (Platform as a Service). This alleviates the developers from time consuming processes like machine provisioning and necessary application deployments. OpenShift provides disk space, CPU resources, memory, network connectivity, and various application deployment platforms like JBoss, Python, MySQL, etc., so  the developers can spend their time on coding and testing new applications rather than spending time figuring out how to acquire and configure these resources.


###OpenShift Components

Here's a list and a brief overview of the diffrent components used by OpenShift.

- Broker: is the single point of contact for all application management activities. It is responsible for managing user logins, DNS, application state, and general orchestration of the application. Customers don’t contact the broker directly; instead they use the Web console, CLI tools, or JBoss tools to interact with Broker over a REST-based API.

- Cartridges: provide the actual functionality necessary to run the user application. OpenShift currently supports many language Cartridges like JBoss, PHP, Ruby, etc., as well as many database Cartridges such as Postgres, MySQL, MongoDB, etc. In case a user need to deploy or create a PHP application with MySQL as a backend, they can just ask the broker to deploy a PHP and a MySQL cartridge on separate “Gears”.

- Gear:  Gears provide a resource-constrained container to run one or more Cartridges. They limit the amount of RAM and disk space available to a Cartridge. For simplicity we can consider this as a separate VM or Linux container for running an application for a specific tenant, but in reality they are containers created by SELinux contexts and PAM namespacing.

- Node: are the physical machines where Gears are allocated. Gears are generally over-allocated on nodes since not all applications are active at the same time.

- BSN (Broker Support Nodes): are the nodes which run applications for OpenShift management. For example, OpenShift uses MongoDB to store various user/app details, and it also uses ActiveMQ to communicate with different application nodes via MCollective. The nodes which host these supporting applications are called as Broker Support Nodes.

- Districts: are resource pools which can be used to separate the application nodes based on performance or environments. For example, in a production deployment we can have two Districts of Nodes, one of which has resources with lower memory/CPU/disk requirements, and another for high performance applications.


### An Overview of application creation process in OpenShift.
 
![Alt text](images/app_deploy.png "App")

The above figure depicts an overview of the different steps involved in creating an application in OpenShift.  If a developer wants to create or deploy a JBoss & MySQL application, they can request the same from different client tools that are available, the choice can be an Eclipse IDE , command line tool (RHC) or even a web browser (management console).

Once the user has instructed the client tool to deploy a JBoss & MySQL application, the client tool makes a web service request to the broker to provision the resources. The broker in turn queries  the Nodes for Gear and Cartridge availability, and if the resources are available, two Gears are created and JBoss and MySQL Cartridges are deployed on them. The user is then notified and they can then access the Gears via SSH and start deploying the code.


### Deployment Diagram of OpenShift via Ansible.
 
![Alt text](images/arch.png "App")

The above diagram shows the Ansible playbooks deploying a highly-available Openshift PaaS environment. The deployment has two servers running LVS (Piranha) for load balancing and provides HA for the Brokers. Two instances of Brokers also run for fault tolerance. Ansible also configures a DNS server which provides name resolution for all the new apps created in the OpenShift environment.

Three BSN (Broker Support Node) nodes provide a replicated MongoDB deployment and the same nodes run three instances of a highly-available ActiveMQ cluster. There is no limitation on the number of application nodes you can deploy–the user just needs to add the hostnames of the OpenShift nodes to the Ansible inventory and Ansible will configure all of them.

Note: As a best practice if  the deployment is in an actual production environment it is recommended to integrate with the infrastructure’s internal DNS server for name resolution and use LDAP or integrate with an existing Active Directory for user authentication.


## Deployment Steps for OpenShift via Ansible

As a first step probably you may want to setup ansible, Assuming the Ansible host is Rhel variant install the EPEL package.

		yum install http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

Once the epel repo is installed ansible can be installed via the following command.

		http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

It is recommended to use seperate machines for the different components of Openshift, but if you are testing it out you could combine the services but atleast four nodes are mandatory as the mongodb and activemq cluster needs atleast three for the cluster to work properly.

As a first step checkout this repository onto you ansible management host and setup the inventory(hosts) as follows.

	git checkout https://github.com/ansible/ansible-examples.git
	
        [dns]
        ec2-54-226-116-175.compute-1.amazonaws.com

        [mongo_servers]
        ec2-54-226-116-175.compute-1.amazonaws.com
        ec2-54-227-131-56.compute-1.amazonaws.com
        ec2-54-227-169-137.compute-1.amazonaws.com

        [mq]
        ec2-54-226-116-175.compute-1.amazonaws.com
        ec2-54-227-131-56.compute-1.amazonaws.com
        ec2-54-227-169-137.compute-1.amazonaws.com

        [broker]
        ec2-54-227-63-48.compute-1.amazonaws.com
        ec2-54-227-171-2.compute-1.amazonaws.com

        [nodes]
        ec2-54-227-146-187.compute-1.amazonaws.com

        [lvs]
        ec2-54-227-176-123.compute-1.amazonaws.com
        ec2-54-227-177-87.compute-1.amazonaws.com

Once the inventroy is setup with hosts in your environment the Openshift stack can be deployed easily by issuing the following command.

        ansible-playbook -i hosts site.yml



### Verifying the Installation

Once the stack has been succesfully deployed, we can check if the diffrent components has been deployed correctly.

- Mongodb: Login to any bsn node running mongodb and issue the following command and a similar output should be displayed. Which displays that the mongo cluster is up with a primary node and two secondary nodes.

        
        [root@ip-10-165-33-186 ~]# mongo 127.0.0.1:2700/admin -u admin -p passme
        MongoDB shell version: 2.2.3
        connecting to: 127.0.0.1:2700/admin
        openshift:PRIMARY> rs.status()
        {
            "set" : "openshift",
            "date" : ISODate("2013-07-21T18:56:27Z"),
            "myState" : 1,
            "members" : [
            {
                "_id" : 0,
                "name" : "ip-10-165-33-186:2700",
                "health" : 1,
                "state" : 1,
                "stateStr" : "PRIMARY",
                "uptime" : 804,
                "optime" : {
                    "t" : 1374432940000,
                    "i" : 1
                },
                "optimeDate" : ISODate("2013-07-21T18:55:40Z"),
                "self" : true
            },
            {
                "_id" : 1,
                "name" : "ec2-54-227-131-56.compute-1.amazonaws.com:2700",
                "health" : 1,
                "state" : 2,
                "stateStr" : "SECONDARY",
                "uptime" : 431,
                "optime" : {
                    "t" : 1374432940000,
                    "i" : 1
                },
                "optimeDate" : ISODate("2013-07-21T18:55:40Z"),
                "lastHeartbeat" : ISODate("2013-07-21T18:56:26Z"),
                "pingMs" : 0
            },
            {
                "_id" : 2,
                "name" : "ec2-54-227-169-137.compute-1.amazonaws.com:2700",
                "health" : 1,
                "state" : 2,
                "stateStr" : "SECONDARY",
                "uptime" : 423,
                "optime" : {
                     "t" : 1374432940000,
                      "i" : 1
                },
                "optimeDate" : ISODate("2013-07-21T18:55:40Z"),
                "lastHeartbeat" : ISODate("2013-07-21T18:56:26Z"),
                "pingMs" : 0
            }   
        ],
        "ok" : 1
        }
        openshift:PRIMARY> 

- ActiveMQ: To verify the cluster status of activeMQ browse to the following url pointing to any one of the mq nodes and provide the credentials as user admin and password as specified in the group_vars/all file. The browser should bring up a page similar to shown below, which shows the other two mq nodes in the cluster to which this node as joined.

        http://ec2-54-226-116-175.compute-1.amazonaws.com:8161/admin/network.jsp


![Alt text](images/mq.png "App")

- Broker: To check if the broker node is installed/configured succesfully, issue the following command on any broker node and a similar output should be displayed. Make sure there is a PASS at the end.

        [root@ip-10-118-127-30 ~]# oo-accept-broker -v
        INFO: Broker package is: openshift-origin-broker
        INFO: checking packages
        INFO: checking package ruby
        INFO: checking package rubygem-openshift-origin-common
        INFO: checking package rubygem-openshift-origin-controller
        INFO: checking package openshift-origin-broker
        INFO: checking package ruby193-rubygem-rails
        INFO: checking package ruby193-rubygem-passenger
        INFO: checking package ruby193-rubygems
        INFO: checking ruby requirements
        INFO: checking ruby requirements for openshift-origin-controller
        INFO: checking ruby requirements for config/application
        INFO: checking that selinux modules are loaded
        NOTICE: SELinux is Enforcing
        NOTICE: SELinux is  Enforcing
        INFO: SELinux boolean httpd_unified is enabled
        INFO: SELinux boolean httpd_can_network_connect is enabled
        INFO: SELinux boolean httpd_can_network_relay is enabled
        INFO: SELinux boolean httpd_run_stickshift is enabled
        INFO: SELinux boolean allow_ypbind is enabled
        INFO: checking firewall settings
        INFO: checking mongo datastore configuration
        INFO: Datastore Host: ec2-54-226-116-175.compute-1.amazonaws.com
        INFO: Datastore Port: 2700
        INFO: Datastore User: admin
        INFO: Datastore SSL: false
        INFO: Datastore Password has been set to non-default
        INFO: Datastore DB Name: admin
        INFO: Datastore: mongo db service is remote
        INFO: checking mongo db login access
        INFO: mongo db login successful: ec2-54-226-116-175.compute-1.amazonaws.com:2700/admin --username admin
        INFO: checking services
        INFO: checking cloud user authentication
        INFO: auth plugin = OpenShift::RemoteUserAuthService
        INFO: auth plugin: OpenShift::RemoteUserAuthService
        INFO: checking remote-user auth configuration
        INFO: Auth trusted header: REMOTE_USER
        INFO: Auth passthrough is enabled for OpenShift services
        INFO: Got HTTP 200 response from https://localhost/broker/rest/api
        INFO: Got HTTP 200 response from https://localhost/broker/rest/cartridges
        INFO: Got HTTP 401 response from https://localhost/broker/rest/user
        INFO: Got HTTP 401 response from https://localhost/broker/rest/domains
        INFO: checking dynamic dns plugin
        INFO: dynamic dns plugin = OpenShift::BindPlugin
        INFO: checking bind dns plugin configuration
        INFO: DNS Server: 10.165.33.186
        INFO: DNS Port: 53
        INFO: DNS Zone: example.com
        INFO: DNS Domain Suffix: example.com
        INFO: DNS Update Auth: key
        INFO: DNS Key Name: example.com
        INFO: DNS Key Value: *****
        INFO: adding txt record named testrecord.example.com to server 10.165.33.186: key0
        INFO: txt record successfully added
        INFO: deleteing txt record named testrecord.example.com to server 10.165.33.186: key0
        INFO: txt record successfully deleted
        INFO: checking messaging configuration
        INFO: messaging plugin = OpenShift::MCollectiveApplicationContainerProxy
        PASS

- Node: To verify if the node installation/configuration has been successfull, issue the follwoing command and check for a similar output as shown below.

        [root@ip-10-152-154-18 ~]# oo-accept-node -v
        INFO: using default accept-node extensions
        INFO: loading node configuration file /etc/openshift/node.conf
        INFO: loading resource limit file /etc/openshift/resource_limits.conf
        INFO: finding external network device
        INFO: checking node public hostname resolution
        INFO: checking selinux status
        INFO: checking selinux openshift-origin policy
        INFO: checking selinux booleans
        INFO: checking package list
        INFO: checking services
        INFO: checking kernel semaphores >= 512
        INFO: checking cgroups configuration
        INFO: checking cgroups processes
        INFO: checking filesystem quotas
        INFO: checking quota db file selinux label
        INFO: checking 0 user accounts
        INFO: checking application dirs
        INFO: checking system httpd configs
        INFO: checking cartridge repository
        PASS

- LVS (LoadBalancer): To check the LoadBalncer Login to the active loadbalancer and issue the follwing command, the output would show the two broker to which the loadbalancer is balancing the traffic.

        [root@ip-10-145-204-43 ~]# ipvsadm
        IP Virtual Server version 1.2.1 (size=4096)
        Prot LocalAddress:Port Scheduler Flags
         -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
        TCP  ip-192-168-1-1.ec2.internal: rr
        -> ec2-54-227-63-48.compute-1.a Route   1      0          0         
        -> ec2-54-227-171-2.compute-1.a Route   2      0          0 

## Creating an APP in Openshift

To create an App in openshift access the management console via any browser, the VIP specified in group_vars/all can used or ip address of any broker node can used.

		https://<ip-of-broker-or-vip>/

The page would as a login, give it as demo/passme. Once logged in follow the screen instructions to create your first Application.
Note: Python2.6 cartridge is by default installed by plabooks, so choose python2.6 as the cartridge.

## Deploying Openshift in EC2

The repo also has playbook that would deploy the Highly Available Openshift in EC2. The playbooks should also be able to deploy the cluster in any ec2 api compatible clouds like Eucalyptus etc..

Before deploying Please make sure:

        - A security groups is created which allows ssh and HTTP/HTTPS traffic.
        - The access/secret key is entered in group_vars/all
        - Also specify the number of nodes required for the cluser in group_vars/all in the variable "count".

Once that is done the cluster can be deployed simply by issuing the command.

        ansible-playbook -i ec2hosts ec2.yml -e id=openshift

Note: 'id' is a unique identifier for the cluster, if you are deploying multiple clusters, please make sure the value given is seperate for each deployments. Also the role of the created instances can figured out checking the tags tab in ec2 console.

###Remove the cluster from EC2.

To remove the deployed openshift cluster in ec2, just run the following command. The id paramter should be the same which was given to create the Instance.

Note: The id can be figured out by checking the tags tab in the ec2 console.

        ansible-playbook -i ec2hosts ec2_remove.yml -e id=openshift5 

  

## HA Tests

Few test's that can be performed to test High Availability are:

- Shutdown any broker and try to create a new Application
- Shutdown anyone mongo/mq node and try to create a new Appliaction.
- Shutdown any loadbalaning machine, and the manamgement application should be available via the VirtualIP.



