# AWS Provisioning Playbooks

**Note**: these playbooks are not intended to serve as an example

The following playbooks are designed to be general purpose provisioning
playbooks. Keep in mind that these are not intended to serve as examples.
They are used by the Ansible team in performing demonstrations.

Here's an example of setting variables required by this provisioner:
```yaml
aws_region: us-east-1
vpc_name: tcross-demo-vpc
aws_instances:
  - subnet_name: tcross-demo-vpc-public-subnet-a
    keypair_name: tcross
    ami_id: ami-b63769a1
    type: t2.micro
    tags:
      Demo: provisioning
  - subnet_name: tcross-demo-vpc-public-subnet-b
    keypair_name: tcross
    ami_id: ami-b63769a1
    type: t2.micro
    tags:
      Demo: provisioning
  - subnet_name: tcross-demo-vpc-public-subnet-c
    keypair_name: tcross
    ami_id: ami-b63769a1
    type: t2.micro
    tags:
      Demo: provisioning

```
