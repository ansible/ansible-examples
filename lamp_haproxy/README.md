Lamp Stack + LoadBalancer(haproxy) + add/remove nodes from cluster + Serial Rolling update of webserserver
----------------------------------------------------------------------------------------------------------

This example is an extension of the simple lamp deployment, In this example we deploy a lampstack with a LoadBalancer in front.
This also has the capablity to add/remove nodes from the deployment. It also includes examples to do a rolling update of a stack
without affecting the service.

###Setup Entire Site.
Firstly we setup the entire stack, configure the 'hosts' inventory file to include the names of your hosts on which the stack would be deployed.

		[webservers]
		web3
		web2
		[dbservers]
		web3
		[lbservers]
		web2

After which we execute the following command to deploy the whole site.

	ansible-playbook -i hosts site.yml

The deployment can be verified by accessing the webpage." lynx http://<ip-of-lb>:8888. multiple access should land you up in diffrent webservers.

###Remove a node from the cluster.
Removal of a node from the cluster would be as simple as executing the following command:

	ansible-playbook -i hosts roles/remove_webservers.yml  --limit=web2

###Adding a node to the cluster.
Adding a node to the cluster can be done by executing the following command:
 
	ansible-playbook -i hosts roles/add_webservers.yml  --limit=web2

###Rolling update of the entire site or  a single hosts
Rolling updates are the preffered way to do an update as this wont affect the end users, In this example the hosts are updated in serial fashion, which means
that only one server would be updated at one time, this behaviour can be changed by setting the 'serial' keyword in webservers.yml file.
Once the code has been updated in the repository which can be defined in the group_vars/all file, execute the following command:

	 ansible-playbook -i hosts roles/rolling_update.yml





	 
