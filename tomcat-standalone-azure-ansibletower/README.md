## Standalone Tomcat Deployment

- Requires Ansible 1.2 or newer
- Expects CentOS/RHEL 6.x hosts

These playbooks deploy a very basic implementation of Tomcat Application Server,
version 7. This playbook has been modified to work with Linux on Azure Ansible 
tower  as well as using command line. 

	ansible-playbook /tomcat-standalone-azure-ansibletower/site.yml -u <user> -k

1. Selinux & Iptables have been removed as same is not applicable for Azure VMs
2. Variable (http_port,https_port, adminname, adminpassword) have been redefined
   in site.yml ss previous ones were throwing error while deployment.
   
When the playbook run completes, you should be able to see the Tomcat
Application Server running on the ports you chose, on the target machines.

This is a very simple playbook and could serve as a starting point for more
complex Tomcat-based projects. 

### Ideas for Improvement

Here are some ideas for ways that these playbooks could be extended:

- Write a playbook to deploy an actual application into the server.
- Deploy Tomcat clustered with a load balancer in front.

We would love to see contributions and improvements, so please fork this
repository on GitHub and send us your changes via pull requests.
