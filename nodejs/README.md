ansible-node-js
===============

Ansible to Install Upstream Version of Node.js on Ubuntu 12.04

## Instructions
Set "home_dir" variable in the main.yml playbook to user's home directory. Set remote host in the production inventory.
Run:
```bash
ansible-playbook -i inventory/production main.yml
```
