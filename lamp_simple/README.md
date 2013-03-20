Building a simple LAMP stack and deploying Application using Ansible Playbooks.
-------------------------------------------

These playbooks are meant to be a reference and starter's guide to building Ansible Playbooks. These playbooks were tested on CentOS 6.x so we recommend that you use CentOS or RHEL to test these modules.

### Installing Ansible

Running this playbook requires setting up Ansible first. Luckily this is a very simple process on CentOS 6.x:

        yum install http://epel.mirrors.arminco.com/6/x86_64/epel-release-6-8.noarch.rpm
        yum install python PyYAML python-paramiko python-jinja2
        git clone git://github.com/ansible/ansible.git
        cd ansible
        source hacking/env-setup

Generate/synchronize your SSH keys (optional you can pass -k parameter to prompt for password)

        ssh-keygen -t rsa
        cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

Create a sample inventory file. The inventory file contains a grouped list of hostnames that are managed by Ansible. The command below will just add "localhost" to the host list.

        echo "localhost" > ansible_hosts

Test if we are setup properly:

        ansible -i ansible_hosts localhost -m ping
                localhost | success >> {
                        "changed": false,
                        "ping": "pong"
                }


Now we set up our LAMP stack. The stack can be on a single node or multiple nodes. The inventory file 'hosts' defines the nodes in which the stacks should be configured.

        [webservers]
        localhost

        [dbservers]
        bensible

Here the webserver would be configured on the local host and the dbserver on a server called "bensible". The stack can be deployed using the following command:

        ansible-playbook -i hosts site.yml

Once done, you can check the results by browsing to http://localhost/index.php. You should see a simple test page and a list of databases retrieved from the database server.