#  Development : Features

**_As a user I would like the ability to…_**



**Adapters/Providers (151) _(128)_**

  Lookup provider support and properties (matrix idea) (5)

  Provision services to Azure (10)

  See more links on services and attributes that link back to provider
components (3)

_  Connect to an Active Directory service (8)_

  Integrate with Route53 balancing (5)

_  Integrate with netscaler (40)_

_  Integrate with vCenter (VMWare) (40)_

_  Integrate with flexpod (40)_



**Services (113) _(56)_**

  Choose OS on a server (8)

  Configure subnets and security (10)

    AWS - security groups (1)

    Rackspace (3)

    Azure (5)

  Provision a subnet across providers (5)

  Configure network interfaces and elastic IPs (10)

  Provision a network interface and elastic IP (5)

  Configure provider specific features e.g.

    AWS - VPC/Auto scaling groups (5)

  Create a “drain” service type, where all services in an environment that
support its interfaces will connect with it (10)

_  Configure VMWare Services (10)_

_    Server (5)_

_    Storage (8)_

_    Networking (8)_

_  Configure flexpod services (20)_

_    Storage (10)_



**Environments (12)**

  DIsplay an environment using the designer component (5)

  Display the current running cost of the environment (2)

  Display detailed information about running services (choose fields important
to you) (5)



**Monitoring (44)**

  DIsplay an environment using the designer component (5)

  Set triggers and actions to be taken on events and metric thresholds (15)

  See detailed service information on mouseover of the chart (4)

  Have a metric controller component on the page that aggregates metrics to
minimise http requests (3)

  See more links on services and attributes that link back to monitoring
providers (2)

  Have an installable agent that can offer me more detailed system monitoring
(10)

  Integrate with new relic to sync available metrics (5)



**Application Stack (67)**

  Design and configure the roles/applications I want provisioned on my server
(20)

  Chef (5)

  Puppet (5)

  Ansible (5)

  CFEngine (10)

  Select from a few example/base recipes for common applications (e.g.
apache/postgres) (5)

  Initiate configuration on multiple OSs (10)

    Linux (2)

    Windows (5)



**Template Designer (22)**

  Present the running total of a template as a service is added (2)

  Drag and configure a service drain (for monitoring) which sucks in all it
can from services in the environment that support it (10)

  Configure storage and IOPS (5)

  Create and configure dynamic properties (5)



**Reporting (20)**

  Integrate with logstash/elasticsearch for event analysis (10)

  Query the event database and display charts/tables of events that match my
query (10)



**Users (70)**

  Add a collaborator to an account/environment (5)

    Email integration (5)

  Assign permissions to accounts/environments/services/etc (30)

  Assign permissions to OS user accounts (15)

  Have transactional emails that notify me of significant events on my account
(5)

  Configure my email notifications (3)

  Provide my billing information (2)

_  Authenticate via Active Directory (5)_





**As a platform I would like the ability to…**



**Technical (77)**

  Asset digests (2)

  Build systems (5)

  User security (2)

  File logging/locations (2)

  Sharding of databases for scalability (5)

  Revision and optimisation of platform recipes (5)

  Show the user a friendlier message if they’re using an old browser (1)

  Database replication (5)

  Database restoration (5)

  Automated maintenance tasks (5)

  Backing up user data externally (5)

  Database Failover (8)

  Key performance metrics (2)

  Load balancing between backend components (5)

  Cassandra operational stuff (5)

  Elasticsearch operational stuff (5)

  Riemann operational stuff (5)

  Graphite operational stuff (5)



**API/Architecture (119) _50_**

  Plugin system for services/adapters (external code repositories) (10)

  Integrate with a payment provider (5)

  Have different service levels/plans (3)

  Keep track of service metrics (such as size) for billing purposes (5)

  Define an application stack to be provisioned on my servers (15)

  Act on service events/notifications (e.g. when this service shuts down) (10)

  Create a connection between providers (8)

  Create a connection between environments (8)

_  Have an installable appliance to be installed on customer premises (50)_

  Create specs for hyperextension library (5)



**Testing (25)**

  Performance and scalability testing (10)

  Security testing - external too  (15)



**Documentation (Technical Writer) (240)**

  API Documentation (40)

  End-user documentation (80)

  Administration Guide (Appliance) (120)

