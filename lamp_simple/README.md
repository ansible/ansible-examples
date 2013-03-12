Building a simple LAMP stack and deploying Application using Ansible Playbooks.
-------------------------------------------

This playbooks is meant to be a reference and starters guide to building  Ansible Playbooks. These playbooks were tested on Centos 6.x so we recommend Centos to test these modules.

### Installing Ansible

Running this playbook requires setting up Ansible first, luckily this is a very simple process on Centos 6.x:

        yum install http://epel.mirrors.arminco.com/6/x86_64/epel-release-6-8.noarch.rpm
        yum install python PyYAML python-paramiko python-jinja2
        git clone git://github.com/ansible/ansible.git
        cd ansible
        source hacking/env-setup

Generate/Synchronize your ssh keys(Optional you can pass -k parameter to prompt for password)

        ssh-keygen -t rsa
        cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

Create a sample inventory file (File containing the hostnames)

        echo "localhost" > ansible_hosts

Test if we are setup properly

        ansible -i ansible_hosts localhost -m ping
                localhost | success >> {
                        "changed": false,
                        "ping": "pong"
                }



Now we setup our Lamp Stack, The stack can be on a single node or multiple nodes. The inventory file 'hosts' defines the nodes in which the stacks should be configured.

        [webservers]
        localhost

        [dbservers]
        bensible

Here the webserver would be configured on the localhost and the dbserver on bensible. The stack can be deployed using the following command.

        ansible-playbook -i hosts site.yml

Once Done, you can check by browsing to http://<ipofhost>/index.php
