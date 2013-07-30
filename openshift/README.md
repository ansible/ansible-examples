# Deploying a Highly Available production ready OpenShift Deployment 

- Requires Ansible 1.2
- Expects CentOS/RHEL 6 hosts (64 bit)


## A Primer into OpenShift Architecture

###OpenShift Overview

OpenShift Origin enables the users to create, deploy and manage applications within the cloud, or in other words it provies a PaaS service (Platform as a service). This aleviates the developers from time consuming processes like machine provisioning and neccesary appliaction deployments. OpenShift provides disk space, CPU resources, memory, network connectivity, and various application like JBoss, python, MySQL etc... So that the developer can spent time on coding, testing his/her new application rather than spending time on figuring out how to get/configure those resources.  

###OpenShift Components

Here's a list and a brief overview of the diffrent components used by OpenShift.

- Broker: is the single point of contact for all application management activities. It is responsible for managing user logins, DNS, application state, and general orchestration of the application. Customers don't contact the broker directly; instead they use the Web console, CLI tools, or JBoss tools to interact with Broker over a REST based API. 

- Cartridges: provide the actual functionality necessary to run the user application. Openshift currently supports many  language cartridges like JBoss, PHP, Ruby, etc., as well as many DB cartridges such as Postgres, Mysql, Mongo, etc. So incase a user need to deploy or create an php application with mysql as backend, he/she can just ask the broker to deploy a php and an mysql cartridgeon seperate gears.

- Gear: Gears provide a resource-constrained container to run one or more cartridges. They limit the amount of RAM and disk space available to a cartridge. For simplicity we can consider this as a seperate vm or linux container for running application for a specific tenant, but in reality they are containers created by selinux contexts and pam namespacing.

- Node: are the physical machines where gears are allocated.  Gears are generally over-allocated on nodes since not all applications are active at the same time. 

- BSN (Broker support Nodes): are the nodes which run applications for OpenShift management. for example OpenShift uses mongodb to
store various user/app details, it also uses ActiveMQ for communincating with different application nodes via Mcollective. These nodes which hosts this supporing applications are called as broker support nodes.

- Districts: are resource pools which can be used to seperate the application nodes based on performance or environments. so for example in a production deployment we can have two districts of nodes one which has resources with lower memory/cpu/disk requirements and another for high performance applications.

### An Overview of application creation process in OpenShift.
 
![Alt text](/images/app_deploy.png "App")


The above figure depicts an overview of diffrent steps invovled in creating an application in OpenShift. So if a developer wants to create or deploy a JBoss & Myql application the user can request the same from diffrent client tools that are available, the choice can be an Eclipse IDE or command line tool (rhc) or even a web browser.

Once the user has instructed the client it makes a web service request to the Broker, the broker inturn check for available resources in the nodes and checks for gear and cartridge availability and if the resources are available two gears are created and JBoss and Mysql cartridges are deployed on them. The user is then notified and the user can then access the gears via ssh and start deploying the code.


### Deployment Diagram of OpenShift via Ansible.
 
![Alt text](/images/arch.png "App")

As the above diagram shows the Ansible playbooks deploys a highly available Openshift Paas environment. The deployment has two servers running lvs (piranha) for loadbalancing and ha for the brokers. Two instances of brokers also run for fault tolerence. Ansible also configures a dns server which provides name resolution for all the new apps created in the Openshift environment.

Three bsn(broker support nodes) nodes provide a replicated mongodb deployment and the same nodes three instances of higly available activeMQ cluster. There is no limitation on the number of application nodes you can add, just add the hostnames of the application nodes in the ansible inventory and ansible will configure all of them for you.

Note: As a best practise if you are deploying an actual production environemnt it is recommended to integrate with your internal DNS server for name resolution and use LDAP or integrate with an existing Active Directory for user authentication.

## Deployment Steps for OpenShift via Ansible

It is recommended to use seperate machines for the different components of Openshift, but if you are testing it out you could combine the services but atleast four nodes are mandatory as the mongodb and activemq cluster needs atleast three for the cluster to work properly.

As a first step checkout this repository onto you ansible management host and setup the inventory(hosts) as follows.

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


![Alt text](/images/mq.png "App")

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

