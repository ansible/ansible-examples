## Tomcat failover with Memcached + Memcached Session Manager + Nginx (load blancer)

- Tested on Ansible 1.9.3 for Debian
- Expects hosts: Centos 6.x

This playbook deploys a failover solution for clustered Tomcat using Nginx as load balancer and Memcached + MSM as session manager.

- Nginx: balances the requests by round robin.
- Memcached: stores `sessionid` of tomcat.
- MSM: manages tomcat session.

For more detail about session management, see https://github.com/magro/memcached-session-manager

This playbook also deploys a demo web app (https://github.com/magro/msm-sample-webapp) to test the session management.


## Initial setup of inventory file

```
[lb_servers]
lbserver

[backend_servers]
tomcat_server_1
tomcat_server_2

[memcached_servers]
cached_server1
cached_server2
```

Edit inventory file `hosts` to suit your requirements and run playbook:

```
    $ ansible-playbook -i host site.yml
```

When finished, open web browser and access to http://nginx_ip/ to start testing.

## Ideas and improvements

- Setup SSL for load balancer.
- HA load balancer.
- Hardening iptables rules.

Pull requests are welcome.

## License

This work is licensed under MIT license.
