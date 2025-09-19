#  Development : Adapters

Relatively lightweight, Adapters handle the connectivity between the ProjectX
Engine and the south-bound APIs. In a lot of cases the Adapter simply handles
REST request/responses, but may also connect to other supporting services,
such as establishing connections to AMQP queues in order to receive realtime
events.

### VMWare

The VMWare adapter will provide the necessary credentials and connectivity for
the vCloud platform. The following Services will be supported via the vCloud
Adapter;

  * vDC Networks
  * vApps

### AWS

The AWS adapter will provide the necessary credentials and connectivity for
the AWS platform. Multiple AWS APIs will be utilised, including EC2 and VPC.
The following Services will be supported via the AWS Adapter;

  * EC2 Instances
  * EBS Volume
  * ELB (Elastic Load Balancers)

### LDAP

The LDAP adapter will provide the ProjectX platform with connectivity to the
enterprises authentication and directory services.

