# Ansible Variable Precedence

This playbook demonstrates the many places that it
is possible to assign variables in Ansible and the
precedence rules that apply.

## Precedence Rules

In order from highest to lowest:

* Register Variables
* Ansible assigned fact vars
* Role Dependency Parameters
* Vars file vars
* Command line extra var
* Playbook vars
* Playbook Role parameter
* Role var
* Inventory Host variable
* Inventory Group variable
* Role default variable

## Usage

To run the playbook, use the predefined script called
`bin/run_playbook`. This defaults to using the `-v` flag
so that the `stdout` of executed tasks is visible. Look
for the `stdout` of the "THE MAIN EVENT echo echo echo"
task to see which variable is currently active with the
highest precedence. To demonstrate the rules in action,
find the variable defined in the `stdout` of your most
recent run of the playbook and go remove or comment out
that specific assignment of the `echo_var`. Once you're
done, if you rerun the playbook, you should see the next
variable in the precedence order as the `stdout` for the
task name mentioned above.

## Prerequisites

* Ansible v1.3
* Ability to SSH into localhost without a password
* `ansible-playbook` script available in Bash shell environment

## v1.2 and earlier

To test the precedence rules against 1.2, simply change the
required role in the playbook from `dummy` to precedence since
v1.2 does not support role dependencies.

The predecedence list using this setup against Ansible v1.2
in order from highest to lowest:

* Register Variables
* Playbook Role parameter
* Vars file vars
* Role var
* Command line extra var
* Playbook vars
* Inventory Host variable
* Inventory Group variable

__Earlier versions than v1.2 were not tested.__

## Official Documentation

[http://www.ansibleworks.com/docs/playbooks2.html#understanding-variable-precedence](http://www.ansibleworks.com/docs/playbooks2.html#understanding-variable-precedence)

