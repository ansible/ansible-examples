## Provisiong EC2 Instance in AWS and Jenkins Deployment into Remote Server

## Pre-Requisites
  
- Requires Ansible 1.2 or newer
- Expects CentOS/RHEL 6 or 7 hosts
- python boto installation

## Install Boto using following Command

	  pip install boto

## Provisioning EC2 Instance

To Deploy EC2 instance, edit the `group_vars/all` file to set any EC2 configuration parameters you need & use `aws_ec2_launch.yml`. 

Deploy EC2 instance using below command:

	  ansible-playbook aws_ec2_launch.yml

## Jenkins Server Deployement


To Deploy Jenkins server using `site.yml`, first edit `hosts` file by adding remote ip's on which jenkins should be installed.

Deploy Jenkins server on to remote IP with username and password into using below command:

	   ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook site.yml -i hosts --extra-vars 'ansible_ssh_pass=YOUR-SSH-PASSWORD-HERE ansible_ssh_user=YOUR-SSH-USERNAME-HERE' 

Deploy Jenkins server onto remote IP with .pem file using below command:

	   ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook site.yml -i hosts  --private-key /mnt/test/cginnovpoc.pem

Deploy Jenkins server standalone using below command:

	   ansible-playbook site.yml
  
When the playbook run completes, you should be able to see the Jenkins Server running on the port 8080.
Eg: localhost:8080

