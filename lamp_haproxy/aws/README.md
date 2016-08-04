LAMP Stack + HAProxy: Example Playbooks for Amazon Web Services
-----------------------------------------------------------------------------

- Requires Ansible 1.2
- Expects CentOS/RHEL 6 hosts

This example is an extension of the simple LAMP deployment. Here we'll install
and configure a web server with an HAProxy load balancer in front, and deploy
an application to the web servers. This set of playbooks also have the
capability to dynamically add and remove web server nodes from the deployment.
It also includes examples to do a rolling update of a stack without affecting
the service.

You can also optionally configure a Nagios monitoring node.

### Initial Site Setup

First, we provision the hosts neccessary for this demonstration using the included playbook, "demo-aws-launch.yml". This will provision the following instances, with the group structure specified below. The hosts are tagged via AWS EC2 tagging and the Ansible inventory sync script (or Tower) will create the appropriate groups from these tags.

		[tag_ansible_group_webservers]
		webserver1
		webserver2
		
		[tag_ansible_group_dbservers]
		dbserver
		
		[tag_ansible_group_lbservers]
		lbserver
		
		[tag_ansible_group_monitoring]
		nagios

After which we execute the following command to deploy the site:

		ansible-playbook -i ec2.py site.yml

The deployment can be verified by accessing the IP address of your load
balancer host in a web browser: http://<ip-of-lb>:8888. Reloading the page
should have you hit different webservers.

The Nagios web interface can be reached at http://<ip-of-nagios>/nagios/

The default username and password are "nagiosadmin" / "nagiosadmin".

### Removing and Adding a Node

Removal and addition of nodes to the cluster is as simple as creating new instances, syncing the
Ansible inventory and re-running:

        ansible-playbook -i ec2.py site.yml

### Rolling Update

Rolling updates are the preferred way to update the web server software or
deployed application, since the load balancer can be dynamically configured
to take the hosts to be updated out of the pool. This will keep the service
running on other servers so that the users are not interrupted.

In this example the hosts are updated in serial fashion, which means that
only one server will be updated at one time. If you have a lot of web server
hosts, this behaviour can be changed by setting the 'serial' keyword in
webservers.yml file.

Once the code has been updated in the source repository for your application
which can be defined in the group_vars/all file, execute the following
command:

	 ansible-playbook -i ec2.py rolling_update.yml

You can optionally pass: -e webapp_version=xxx to the rolling_update
playbook to specify a specific version of the example webapp to deploy.
