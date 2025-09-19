module CommonConstants
	DEFAULT_TIME_FORMATE = "%Y-%m-%d %H:%M:%S %Z"
	CloudStreet_KEY = Rails.application.secrets.cloudstreet_secret_token

  SAAS_PRODUCT_URL = 'https://aws.amazon.com/marketplace/pp/B07FYM16VP'
  MONGOID_YML = File.exist?("/data/mount/mongoid.yml") ? "/data/mount/mongoid.yml" : "config/mongoid.yml"
  SAAS_PRODUCT_CODE = ENV["MP_PRODUCT_CODE"]
  METERING_DIMENSION = 'SAAS_BASE_3_0'
  PROVIDER = 'Azure'
  SAAS_SUBSCRIPTION_SQS_NAME = 'AWSMarketplaceSaasSubscriptionsNotification'
  SAAS_SUBSCRIPTION_EVENTS = [
    'subscribe-success',
    'subscribe-fail',
    'unsubscribe-pending',
    'unsubscribe-success'
  ]
  SAAS_SUBSCRIPTION_ACCESS = {
    access_key_id: ENV["AWS_ACCESS_KEY_ID"],
    secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
  }

  RDS_DUMP_ACCESS = {
    access_key_id: ENV["AWS_ACCESS_KEY_ID"],
    secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
  }

	STATISTICS   = %w(Average Sum SampleCount Maximum Minimum)

	METRIC_NAMES = {
		rds: %w(CPUUtilization BinLogDiskUsage DatabaseConnections DiskQueueDepth FreeableMemory FreeStorageSpace ReplicaLag SwapUsage ReadIOPS WriteIOPS ReadLatency WriteLatency ReadThroughput WriteThroughput NetworkReceiveThroughput NetworkTransmitThroughput),
		server: %w(CPUUtilization CPUCreditUsage CPUCreditBalance DiskReadOps DiskWriteOps DiskReadBytes DiskWriteBytes NetworkIn NetworkOut StatusCheckFailed StatusCheckFailed_Instance StatusCheckFailed_System NetworkPacketsIn NetworkPacketsOut),
		volume: %w(VolumeReadBytes VolumeWriteBytes VolumeReadOps VolumeWriteOps VolumeTotalReadTime VolumeTotalWriteTime VolumeIdleTime VolumeQueueLength VolumeThroughputPercentage VolumeConsumedReadWriteOps),
		load_balancer: %w(HealthyHostCount UnHealthyHostCount RequestCount Latency HTTPCode_ELB_4XX HTTPCode_ELB_5XX HTTPCode_Backend_2XX HTTPCode_Backend_3XX HTTPCode_Backend_4XX HTTPCode_Backend_5XX BackendConnectionErrors SurgeQueueLength SpilloverCount)
	}

  AZURE_METRIC_UNIT_MAP = {
    'Percentage Cpu' => 'Percent',
    'OS Disk Read Operations/Sec' => 'BytesPerSecond',
    'OS Disk Write Operations/Sec' => 'BytesPerSecond',
    'Disk Read Bytes' => 'Bytes',
    'Disk Write Bytes' => 'Bytes',
    'Network In Total' => 'Bytes',
    'Network Out Total' => 'Bytes',
    'VM Cached IOPS Consumed Percentage' => 'Percent',
    'VM Uncached IOPS Consumed Percentage' =>'Percent',
  }


  AZURE_SQL_DB_METRIC_UNIT_MAP = {
    'connection_failed' => 'Count',
    'connection_successful' => 'Count',
    'cpu_percent' => 'Percent',
    'delta_num_of_bytes_read' => 'Bytes',
    'dtu_consumption_percent' => 'Percent',
    'dtu_limit' => 'Count',
    'dtu_used' => 'Count',
    'physical_data_read_percent' => 'Percent',
    'allocated_data_storage' => 'Bytes',
    'storage' => 'Bytes',
    'storage_percent'=> 'Bytes'
  }



  AZURE_METRIC_CSV_COLUMN_NAMES = %w{Id Name ProviderId SubscriptionId RegionCode VMSize DiskSize CPUPercentage OSDiskReadOperationsSec OSDiskWriteOperationsSec DiskReadBytes DiskWriteBytes NetworkInTotal NetworkOutTotal MetricUnit VmTags CostByHour}.freeze

	NAMESPACES = {
		rds: 'AWS/RDS',
		server: 'AWS/EC2',
		volume: 'AWS/EBS',
		load_balancer: 'AWS/ELB'
	}	

	DIMENSIONS = {
		'AWS/EC2' => 'InstanceId',
		'AWS/RDS' => 'DBInstanceIdentifier',
		'AWS/EBS' => 'VolumeId',
		'AWS/ELB' => 'LoadBalancerName'# AvailabilityZone
	}

	SERVICE_NAMING_MAP =  YAML.load_file(Rails.root.join('data', 'services/default_services_names_map.yml'))

  TEMPLATE_COSTS = {
  	 base: 'https://pricing.us-east-1.amazonaws.com',
  	 index: '/offers/v1.0/aws/index.json',
  	 costings_for: ['AmazonRDS', 'AmazonEC2']
  }

  PRIORITIES = ("0".."15").to_a.each {|count| count.prepend("tier-")}

  REGIONS = %w(af-south-1 ap-east-1 eu-south-1 eu-west-3 eu-north-1 me-south-1 ap-south-1 ap-northeast-2 ap-southeast-1 ap-southeast-2 ap-northeast-1 ca-central-1 eu-central-1 eu-west-1 eu-west-2 sa-east-1 us-east-1 us-east-2 us-west-1 us-west-2 us-gov-east-1 us-gov-west-1)

  SERVICE_TYPE_MAP = {
    "Services::Compute::Server::AWS" => 'Server',
    "Services::Compute::Server::Volume::AWS" => 'Volume',
    "Services::Network::RouteTable::AWS" => 'Route Table',
    "Services::Network::AutoScaling::AWS" => 'Auto Scaling Group',
    "Services::Database::Rds::AWS" => {
      "postgres"=>'PostgreSQL',
      "mysql"=>'MySQL',
      "sqlserver-ee" => "SQL Server Enterprise Edition",
      "sqlserver-se"=>'SQL Server Standard Edition',
      "sqlserver-web"=>'SQL Server Web Edition',
      "sqlserver-ex"=>'SQL Server Express Edition',
      "oracle-se1"=>'Oracle Database Standard Edition One',
      "oracle-se2"=>'Oracle Database Standard Edition Two',
      "oracle-se"=>'Oracle Database Standard Edition',
      "oracle-ee"=>'Oracle Database Enterprise Edition',
      "aurora" => 'Aurora - compatible with MySQL 5.6.10a'
    },
    "Services::Network::AutoScalingConfiguration::AWS" => 'Launch Configuration',
    "Services::Network::SecurityGroup::AWS" => 'Security Group',
    "Services::Network::SubnetGroup::AWS" => 'Subnet Group',
    "Services::Network::LoadBalancer::AWS" => 'Load Balancer',
    "Services::Network::Subnet::AWS" => 'Subnet',
    "Services::Vpc" => 'VPC'
  }

  REVISION_SERVICES = %w(Services::Compute::Server Services::Compute::Server::Volume Services::Network::ElasticIP Services::Database::Rds Services::Network::Subnet Services::Network::AutoScalingConfiguration Services::Network::SecurityGroup Services::Network::AutoScaling Services::Network::LoadBalancer)

  SIZE_MAPPING = {
    't1.micro' => 't2.micro', 

    'm1.small' => 't2.small', 
    'm1.medium' => 'm3.medium', 
    'm1.large' => 'm4.large', 
    'm1.xlarge' => 'm4.xlarge',
     
    'm3.large' => 'm4.large', 
    'm3.xlarge' => 'm4.xlarge', 
    'm3.2xlarge' => 'm4.2xlarge', 

    'c3.large' => 'c4.large',
    'c3.xlarge' => 'c4.xlarge', 
    'c3.2xlarge' => 'c4.2xlarge', 
    'c3.4xlarge' => 'c4.4xlarge', 
    'c3.8xlarge' => 'c4.8xlarge',

    'r3.large' => 'r4.large',
    'r3.xlarge' => 'r4.xlarge', 
    'r3.2xlarge' => 'r4.2xlarge', 
    'r3.4xlarge' => 'r4.4xlarge', 
    'r3.8xlarge' => 'r4.8xlarge', 

    'i2.xlarge' => 'i3.xlarge', 
    'i2.2xlarge' => 'i3.2xlarge', 
    'i2.4xlarge' => 'i3.4xlarge', 
    'i2.8xlarge' => 'i3.8xlarge', 

    'c1.medium' => 'c4.large', 
    'c1.xlarge' => 'c4.2xlarge', 

    't2.nano' => 't3.nano', 
    't2.micro'=> 't3.micro', 
    't2.small' => 't3.small', 
    't2.medium' => 't3.medium', 
    't2.large' => 't3.large', 
    't2.xlarge' => 't3.xlarge', 
    't2.2xlarge' => 't3.2xlarge', 

    'm4.large' => 'm5.large',
    'm4.xlarge' => 'm5.xlarge',
    'm4.2xlarge' => 'm5.2xlarge',
    'm4.4xlarge' => 'm5.4xlarge',
    'm4.10xlarge' => 'm5.8xlarge',
    'm4.16xlarge' => 'm5.12xlarge',

    'c4.large' => 'c5.large',
    'c4.xlarge' => 'c5.xlarge',
    'c4.2xlarge' => 'c5.2xlarge',
    'c4.4xlarge' => 'c5.4xlarge',
    'c4.8xlarge' => 'c5.9xlarge',

    'r4.large' => 'r5.large',
    'r4.xlarge' => 'r5.xlarge',
    'r4.2xlarge' => 'r5.2xlarge',
    'r4.4xlarge' => 'r5.4xlarge',
    'r4.8xlarge' => 'r5.8xlarge',
    'r4.16xlarge' => 'r5.16xlarge',
  }
  
  RDS_SIZE_MAPPING = { 
    'db.t1.micro' => 'db.t2.micro', 

    'db.m1.small' => 'db.t2.small', 
    'db.m1.medium' => 'db.m3.medium', 
    'db.m1.large' => 'db.m4.large',
    'db.m1.xlarge' => 'db.m4.xlarge',

    'db.m2.xlarge' => 'db.r3.large',
    'db.m2.2xlarge' => 'db.r3.xlarge' ,
    'db.m2.4xlarge' => 'db.r3.2xlarge',

    'db.m3.large' => 'db.m4.large',
    'db.m3.xlarge' => 'db.m4.xlarge',
    'db.m3.2xlarge' => 'db.m4.2xlarge',

    'db.t2.micro' => 'db.t3.micro',
    'db.t2.small' => 'db.t3.small',
    'db.t2.medium' => 'db.t3.medium',
    'db.t2.large' => 'db.t3.large',
    'db.t2.xlarge' => 'db.t3.xlarge',
    'db.t2.2xlarge' => 'db.t3.2xlarge',

    'db.m4.large' => 'db.m5.large',
    'db.m4.xlarge' => 'db.m5.xlarge',
    'db.m4.2xlarge' => 'db.m5.2xlarge',
    'db.m4.4xlarge' => 'db.m5.4xlarge'
  }

  REGION_CODES = {
    'APN1': 'Asia Pacific (Tokyo)',
    'APE1': 'Asia Pacific (Hong Kong)',
    'APN2': 'Asia Pacific (Seoul)',
    'APS1': 'Asia Pacific (Singapore)',
    'APS2': 'Asia Pacific (Sydney)',
    'APS3': 'Asia Pacific (Mumbai)',
    'CAN1': 'Canada (Central)',
    'CPT': 'Africa (Cape Town)',
    'EUC1': 'EU (Frankfurt)',
    'EU': 'EU (Ireland)',
    'EUN1': 'EU (Stockholm)',
    'EUW2': 'EU (London)',
    'SAE1': 'South America (Sao Paulo)',
    'UGW1': 'AWS GovCloud (US)',
    'USE1': 'US East (N. Virginia)',
    'USE2': 'US East (Ohio)',
    'USW1': 'US West (N. California)',
    'USW2': 'US West (Oregon)',
    'CNN1': 'China (Beijing)',
    'EUW3': 'EU (Paris)',
    'MES1': 'Middle East (Bahrain)',
    'global': 'global',
    'EUW1': 'EU (Ireland)',
    '': 'No Region'
  }.freeze

  CHILD_ORG_HOST_NAME = Settings.host.sub(/^https:\/\/clientweb(?:-apse2|-cac1|-ff|-apse1|-euw2)?\./, 'https://').split("//").last

  PUBLIC_HOST_NAME = {
     "dev" => 'pbweb.cloudstreet.co',
     "staging" => 'staging.cloudstreet.io',
     "production" => 'web.cloudstreet.com'
  }.freeze


# Comman Constants for Right Sizing Start

METRICS = %w{NetworkIn NetworkOut DiskReadOps DiskWriteOps CPUUtilization MemoryUtilization}.freeze

UNITS = {
  'CPUUtilization'=> 'Percent',
  'NetworkIn' => 'Bytes',
  'NetworkOut' => 'Bytes',
  'DiskReadOps' => 'Count',
  'DiskWriteOps' => 'Count',
  'MemoryUtilization' => 'Percent'
}

DEFAULT_KEYS = {
  access_key_id: Rails.application.secrets['aws_access_key_id'],
  secret_access_key: Rails.application.secrets['aws_secret_access_key']
}

AZ_CODES = {
  'us-east-1': 'US East (N. Virginia)',
  'us-east-2': 'US East (Ohio)',
  'us-west-1': 'US West (N. California)',
  'us-west-2': 'US West (Oregon)',
  'ca-central-1': 'Canada (Central)',
  'eu-west-1': 'EU (Ireland)',
  'eu-central-1': 'EU (Frankfurt)',
  'eu-west-2': 'EU (London)',
  'ap-northeast-1': 'Asia Pacific (Tokyo)',
  'ap-northeast-2': 'Asia Pacific (Seoul)',
  'ap-southeast-1': 'Asia Pacific (Singapore)',
  'ap-southeast-2': 'Asia Pacific (Sydney)',
  'ap-south-1': 'Asia Pacific (Mumbai)',
  'af-south-1': 'Africa (Cape Town)',
  'ap-east-1': 'Asia Pacific (Hong Kong)',
  'sa-east-1': 'South America (São Paulo)',
  'eu-south-1': 'EU (Milan)',
  'us-gov-west-1': 'AWS GovCloud (US)',
  'cn-north-1': 'China (Beijing)',
  'eu-west-3': 'EU (Paris)',
  'eu-north-1': 'EU (Stockholm)',
  'me-south-1': 'Middle East (Bahrain)',
  'global': 'global',
  '': 'No Region'
}.freeze

METRIC_COLUMN_NAMES = %w{humanReadableTimestamp timestamp accountId az  instanceId instanceType
  instanceTags ebsBacked volumeIds instanceLaunchTime humanReadableInstanceLaunchTime
  CPUUtilization MemoryUtilization NetworkIn NetworkOut DiskReadOps DiskWriteOps}.freeze

CSV_PATH = "https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonEC2/current/index.csv"
RDS_JSON_PATH = "https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonRDS/current/index.json"

RIGHT_SIZE_COLUMNS = %w{humanReadableTimestamp timestamp accountId az instanceId instanceType
  instanceTags ebsBacked volumeIds instanceLaunchTime humanReadableInstanceLaunchTime CPUUtilization
  MemoryUtilization NetworkIn NetworkOut DiskReadOps DiskWriteOps}

BUCKET = {
  bucket_name: "rightsizing-data"
}

TABLE_RIGHT_SIZING = 'right_sizing_data'

TABLE_PRICE_LISTING = 'price_listing'

# Comman Constants for Right Sizing End
  THREAT_MAPPING = {
  "Default Security Groups In Use" => ["CreateSecurityGroup"],
  "Default Security Group with rules" => %w[AuthorizeSecurityGroupIngress AuthorizeSecurityGroupEgress CreateSecurityGroup],
  "Security Group All Ports Open to All" => %w[AuthorizeSecurityGroupIngress AuthorizeSecurityGroupEgress CreateSecurityGroup],
  "Unrestricted _ARG_0_ Access" => %w[CreateSecurityGroup AuthorizeSecurityGroupEgress RevokeSecurityGroupIngress],
  "Unrestricted ICMP Access" => %w[AuthorizeSecurityGroupIngress AuthorizeSecurityGroupEgress],
  "Unrestricted NetBIOS Access" => %w[CreateSecurityGroup AuthorizeSecurityGroupEgress AuthorizeSecurityGroupIngress],
  "Security Group known Ports Open to All" => %w[CreateSecurityGroup AuthorizeSecurityGroupIngress],
  "Security Group non HTTP Ports Open to All (TCP/UDP)" => %w[CreateSecurityGroup AuthorizeSecurityGroupIngress],
  "Unrestricted Inbound Access on Uncommon Ports" => %w[AuthorizeSecurityGroupIngress CreateSecurityGroup],
  "Unrestricted Outbound Access on All Ports" => %w[CreateSecurityGroup AuthorizeSecurityGroupIngress],
  "Unrestricted network traffic within security group" => %w[CreateSecurityGroup RevokeSecurityGroupIngress],
  "Security Group known Ports to Self" => %w[CreateSecurityGroup AuthorizeSecurityGroupIngress],
  "Security Group Port Range" => %w[CreateSecurityGroup AuthorizeSecurityGroupIngress],
  "SecurityGroup RFC 1918" => %w[CreateSecurityGroup AuthorizeSecurityGroupIngress],
  "Security Group not in use" => %w[CreateSecurityGroup RevokeSecurityGroupEgress],
  "Security Group Rules Counts" => %w[CreateSecurityGroup AuthorizeSecurityGroupIngress],
  "Default Security Group Unrestricted" => %w[CreateSecurityGroup RevokeSecurityGroupEgress AuthorizeSecurityGroupIngress],
  "Descriptions for Security Group Rules" => %w[RevokeSecurityGroupEgress RevokeSecurityGroupIngress],
  "Security Group Naming Conventions" => %w[CreateSecurityGroup RevokeSecurityGroupEgress],
  "Publicly Shared AMI" => %w[CreateImage ModifyImageAttribute CopyImage],
  "EC2 AMI Too Old" => ["CreateImage"],
  "AWS AMI Encryption" => %w[CreateImage ModifyImageAttribute],
  "AMI Naming Conventions" => %w[CreateImage CopyImage],
  "RDS Encryption Enabled" => %w[CreateDBInstance ModifyDBInstance RestoreDBInstanceFromDBSnapshot],
  "Automated Backup Disabled" => %w[CreateDBInstance ModifyDBInstance RestoreDBInstanceFromDBSnapshot],
  "RDS Auto Minor Version Upgrade" => %w[CreateDBInstance ModifyDBInstance RestoreDBInstanceFromDBSnapshot],
  "RDS Sufficient Backup Retention Period" => %w[CreateDBInstance ModifyDBInstance RestoreDBInstanceFromDBSnapshot],
  "Short Backup Retention Period" => %w[ModifyDBInstance CreateDBInstance RestoreDBInstanceFromDBSnapshot],
  "RDS Multi-AZ" => %w[CreateDBInstance ModifyDBInstance],
  "RDS Postgres with Invalid Certificate" => %w[ModifyDBInstance CreateDBInstance],
  "Amazon RDS Public Snapshots" => ["CreateDBInstance"],
  "RDS General Purpose SSD" => ["ModifyDBInstance"],
  "RDS Master Username" => %w[CreateDBInstance ModifyDBInstance],
  "RDS Free Storage Space" => %w[CreateDBInstance ModifyDBInstance],
  "Underutilized RDS Instance" => %w[CreateDBInstance ModifyDBInstance],
  "EC2 Instance Termination Protection" => %w[RunInstances ModifyInstanceAttribute],
  "EC2 Instance Too Old" => ["RunInstances"],
  "Security Group Name Prefixed With 'launch-wizard'" => %w[RunInstances ModifyInstanceAttribute],
  "EC2 Instance Using IAM Roles" => %w[ModifyInstanceAttribute RunInstances],
  "EC2 Instance Detailed Monitoring" => %w[RunInstances ModifyInstanceAttribute],
  "EC2 Instance Naming Conventions" => ["RunInstances"],
  "EC2 Instance Security Group Rules Counts" => %w[ModifyInstanceAttribute RunInstances],
  "Instance In Auto Scaling Group" => %w[AttachInstances CreateAutoScalingGroup UpdateAutoScalingGroup],
  "Enable AWS EC2 Hibernation" => ["ModifyInstanceAttribute"],
  "Approved/Golden AMIs" => %w[RunInstances ModifyInstanceAttribute],
  "EBS Encrypted" => %w[CreateVolume],
  "Amazon EBS Public Snapshots" => %w[ModifySnapshotAttribute ModifyDBSnapshotAttribute],
  "EBS Snapshot Encrypted" => %w[ModifySnapshotAttribute ModifyDBSnapshotAttribute],
  "EBS Volumes Attached To Stopped EC2 Instances" => %w[CreateVolume ModifyVolume],
  "EBS Volumes Recent Snapshots" => %w[CreateSnapshot CreateDBSnapshot ModifySnapshotAttribute ModifyDBSnapshotAttribute],
  "Unrestricted Network ACL Inbound Traffic" => %w[CreateVpc ModifyVpcAttribute CreateNetworkAcl ReplaceNetworkAclEntry],
  "Unrestricted Network ACL Outbound Traffic" => %w[CreateVpc ModifyVpcAttribute CreateNetworkAcl ReplaceNetworkAclEntry],
  "Unused VPC Internet Gateways" => %w[CreateInternetGateway DetachInternetGateway],
  "Root Account Access Keys Present" => [],
  "Root Account Active Signing Certificates" => [],
  "Root Account Usage" => [],
  "Root MFA Enabled" => [],
  "IAM User Password Expiry 7 Days" => [],
  "IAM User Password Expiry 30 Days" => [],
  "IAM User Password Expiry 45 Days" => [],
  "Credentials Last Used - Access Key" => [],
  "Credentials Last Used - Password" => [],
  "_ARG_0_" => [],
  "IAM User With Password And Access Keys" => [],
  "Inactive IAM Console User" => [],
  "MFA For IAM Users With Console Password" => [],
  "Unnecessary Access Keys" => [],
  "Unnecessary SSH Public Keys" => [],
  "Unused IAM User" => [],
  "Access Keys Rotated 30 Days" => [],
  "Access Keys Rotated 45 Days" => [],
  "Access Keys Rotated 90 Days" => [],
  "Hardware MFA for AWS Root Account" => [],
  "AWS IAM Users with Admin Privileges" => [],
  "Canary Access Token" => [],
  "IAM User Policies" => [],
  "Access Keys During Initial IAM User Setup" => [],
  "IAM Role Policy Too Permissive" => [],
  "Cross-Account Access Lacks External ID and MFA" => [],
  "Unused IAM Group" => [],
  "IAM Group With Inline Policies" => [],
  "CloudTrail Bucket MFA Delete Enabled" => [],
  "_ARG_2_" => %w[CreateBucket PutBucketAcl],
  "CloudTrail Enabled" => [],
  "CloudTrail Global Services Enabled" => [],
  "CloudTrail Data Events" => [],
  "CloudTrail Delivery Failing" => [],
  "CloudTrail Log File Integrity Validation" => [],
  "CloudTrail Logs Encrypted" => [],
  "CloudTrail Management Events" => [],
  "CloudTrail S3 Bucket Logging Enabled" => %w[CreateBucket PutBucketLogging],
  "Enable Object Lock for CloudTrail S3 Buckets" => %w[CreateBucket PutBucketAcl],
  "CloudTrail Integrated With CloudWatch" => [],
  "AWS Config Changes Alarm" => [],
  "AWS Console Sign In Without MFA" => [],
  "AWS Organizations Changes Alarm" => [],
  "Authorization Failures Alarm" => [],
  "CMK Disabled or Scheduled for Deletion Alarm" => [],
  "CloudTrail Changes Alarm" => [],
  "Console Sign-in Failures Alarm" => [],
  "EC2 Instance Changes Alarm" => [],
  "EC2 Large Instance Changes Alarm" => [],
  "IAM Policy Changes Alarm" => [],
  "Internet Gateway Changes Alarm" => [],
  "Network ACL Changes Alarm" => [],
  "Root Account Usage Alarm" => [],
  "Route Table Changes Alarm" => [],
  "S3 Bucket Changes Alarm" => [],
  "Security Group Changes Alarm" => [],
  "VPC Changes Alarm" => [],
  "Expired SSL/TLS Certificate" => [],
  "SSL/TLS Certificate Expiry 30 Days" => [],
  "SSL/TLS Certificate Expiry 45 Days" => [],
  "SSL/TLS Certificate Expiry 7 Days" => [],
  "Pre-Heartbleed Server Certificates" => %w[CreateInstanceProfile AssociateIamInstanceProfile],
  "Auto Scaling Group Cooldown Period" => %w[CreateAutoScalingGroup UpdateAutoScalingGroup],
  "Auto Scaling Group Referencing Missing ELB" => %w[AttachLoadBalancers DetachLoadBalancers],
  "Same Availability Zones In ASG And ELB" => %w[CreateAutoScalingGroup UpdateAutoScalingGroup AttachLoadBalancers DetachLoadBalancers],
  "Launch Configuration Referencing Missing AMI" => ["CreateLaunchConfiguration"],
  "Launch Configuration Referencing Missing Security Groups" => ["CreateLaunchConfiguration"],
  "Unused AWS EC2 Key Pairs" => ["CreateKeyPair"],
  "Unused Elastic Network Interfaces" => %w[CreateNetworkInterface AttachNetworkInterface ModifyNetworkInterfaceAttribute AssignPrivateIpAddresses UnassignPrivateIpAddresses],
  "S3 Bucket Logging Enabled" => %w[CreateBucket PutBucketLogging],
  "Versioned bucket without MFA delete" => ["CreateBucket"],
  "S3 Bucket Versioning Enabled" => %w[CreateBucket PutBucketVersioning],
  "S3 Buckets with static website enabled" => %w[CreateBucket PutBucketWebsite],
  "DNS Compliant S3 Bucket Names" => ["CreateBucket"],
  "ELB Connection Draining Enabled" => %w[CreateLoadBalancer ModifyLoadBalancerAttributes CreateApplicationLoadBalancer ModifyApplicationLoadBalancerAttributes CreateNetworkLoadBalancer ModifyNetworkLoadBalancerAttributes],
  "ELB Cross-Zone Load Balancing Enabled" => %w[CreateLoadBalancer ModifyLoadBalancerAttributes CreateApplicationLoadBalancer ModifyApplicationLoadBalancerAttributes CreateNetworkLoadBalancer ModifyNetworkLoadBalancerAttributes],
  "ELB Listener Security" => %w[CreateLoadBalancer CreateApplicationLoadBalancer CreateNetworkLoadBalancer CreateApplicationLoadBalancerListener CreateNetworkLoadBalancerListener CreateLoadBalancerListeners ModifyApplicationLoadBalancerListener ModifyNetworkLoadBalancerListener],
  "ELB Minimum Number Of EC2 Instances" => %w[RegisterInstancesWithLoadBalancer ModifyLoadBalancerAttributes],
  "ELB Security Group" => %w[CreateLoadBalancer CreateApplicationLoadBalancer CreateNetworkLoadBalancer ApplySecurityGroupsToLoadBalancer SetSecurityGroups],
  "Internet Facing ELBs (Not Scored)" => %w[CreateLoadBalancer ModifyLoadBalancerAttributes CreateApplicationLoadBalancer ModifyApplicationLoadBalancerAttributes CreateNetworkLoadBalancer ModifyNetworkLoadBalancerAttributes],
  "ELB Instances Distribution Across AZs" => %w[CreateLoadBalancer ModifyLoadBalancerAttributes CreateApplicationLoadBalancer ModifyApplicationLoadBalancerAttributes CreateNetworkLoadBalancer ModifyNetworkLoadBalancerAttributes],
  "AWS Organizations In Use" => [],
  "AWS Organizations Enable All Features" => [],
  "KMS Customer Master Key Pending Deletion" => %w[CreateAlias EnableKey],
  "Unused Customer Master Key" => ["CreateAlias"],
  "Key Rotation Enabled" => %w[CreateAlias EnableKey],
  "Key Exposed" => ["CreateAlias"],
  "AWS Config Enabled" => [],
  "AWS Config Global Resources" => [],
  "Config Delivery Failing" => [],
  "AWS Config Referencing Missing S3 Bucket" => [],
  "AWS IAM Password Policy" => []
}.freeze

  AZURE_VM_SIZE = {
    general_purpose: %w[
      Standard_A1_v2
      Standard_A2_v2
      Standard_A4_v2
      Standard_A8_v2
      Standard_A2m_v2
      Standard_A4m_v2
      Standard_A8m_v2
      Standard_B1ls
      Standard_B1s
      Standard_B1ms
      Standard_B2s
      Standard_B2ms
      Standard_B4ms
      Standard_B8ms
      Standard_B12ms
      Standard_B16ms
      Standard_B20ms
      Standard_DC1s_v2
      Standard_DC2s_v2
      Standard_DC4s_v2
      Standard_DC8_v2
      Standard_D1_v2
      Standard_D2_v2
      Standard_D3_v2
      Standard_D4_v2
      Standard_D5_v2
      Standard_DS1_v2
      Standard_DS2_v2
      Standard_DS3_v2
      Standard_DS4_v2
      Standard_DS5_v2
      Standard_D2_v3
      Standard_D4_v3
      Standard_D8_v3
      Standard_D16_v3
      Standard_D32_v3
      Standard_D48_v3
      Standard_D64_v3
      Standard_D2s_v3
      Standard_D4s_v3
      Standard_D8s_v3
      Standard_D16s_v3
      Standard_D32s_v3
      Standard_D48s_v3
      Standard_D64s_v3
      Standard_D2a_v4
      Standard_D4a_v4
      Standard_D8a_v4
      Standard_D16a_v4
      Standard_D32a_v4
      Standard_D48a_v4
      Standard_D64a_v4
      Standard_D96a_v4
      Standard_D2as_v4
      Standard_D4as_v4
      Standard_D8as_v4
      Standard_D16as_v4
      Standard_D32as_v4
      Standard_D48as_v4
      Standard_D64as_v4
      Standard_D96as_v4
      Standard_D2d_v4
      Standard_D4d_v4
      Standard_D8d_v4
      Standard_D16d_v4
      Standard_D32d_v4
      Standard_D48d_v4
      Standard_D64d_v4
      Standard_D2ds_v4
      Standard_D4ds_v4
      Standard_D8ds_v4
      Standard_D16ds_v4
      Standard_D32ds_v4
      Standard_D48ds_v4
      Standard_D64ds_v4
      Standard_D2_v4
      Standard_D4_v4
      Standard_D8_v4
      Standard_D16_v4
      Standard_D32_v4
      Standard_D48_v4
      Standard_D64_v4
      Standard_D2s_v4
      Standard_D4s_v4
      Standard_D8s_v4
      Standard_D16s_v4
      Standard_D32s_v4
      Standard_D48s_v4
      Standard_D64s_v4
      Standard_D2as_v6
      Standard_D4as_v6
      Standard_D8as_v6
      Standard_D2ads_v6
      Standard_D4ads_v6
      Standard_D8ads_v6
      Standard_D16ads_v6
      Standard_D32ads_v6
      Standard_D48ads_v6
      Standard_D64ads_v6
      Standard_D96ads_v6
      Standard_D16as_v6
      Standard_D32as_v6
      Standard_D48as_v6
      Standard_D64as_v6
      Standard_D96as_v6
      Standard_D2als_v6
      Standard_D4als_v6
      Standard_D8als_v6
      Standard_D16als_v6
      Standard_D32als_v6
      Standard_D48als_v6
      Standard_D64als_v6
      Standard_D96als_v6
      Standard_D2alds_v6
      Standard_D4alds_v6
      Standard_D8alds_v6
      Standard_D16alds_v6
      Standard_D32alds_v6
      Standard_D48alds_v6
      Standard_D64alds_v6
      Standard_D96alds_v6
      Standard_D2_v5
      Standard_D4_v5
      Standard_D8_v5
      Standard_D16_v5
      Standard_D32_v5
      Standard_D48_v5
      Standard_D64_v5
      Standard_D96_v5
      Standard_D2s_v5
      Standard_D4s_v5
      Standard_D8s_v5
      Standard_D16s_v5
      Standard_D32s_v5
      Standard_D48s_v5
      Standard_D64s_v5
      Standard_D96s_v5
      Standard_D2ls_v5
      Standard_D4ls_v5
      Standard_D8ls_v5
      Standard_D16ls_v5
      Standard_D32ls_v5
      Standard_D48ls_v5
      Standard_D64ls_v5
      Standard_D96ls_v5
      Standard_D2lds_v5
      Standard_D4lds_v5
      Standard_D8lds_v5
      Standard_D16lds_v5
      Standard_D32lds_v5
      Standard_D48lds_v5
      Standard_D64lds_v5
      Standard_D96lds_v5
      Standard_D2d_v5
      Standard_D4d_v5
      Standard_D8d_v5
      Standard_D16d_v5
      Standard_D32d_v5
      Standard_D48d_v5
      Standard_D64d_v5
      Standard_D96d_v5
      Standard_D2ds_v5
      Standard_D4ds_v5
      Standard_D8ds_v5
      Standard_D16ds_v5
      Standard_D32ds_v5
      Standard_D48ds_v5
      Standard_D64ds_v5
      Standard_D96ds_v5
      Standard_D2as_v5
      Standard_D4as_v5
      Standard_D8as_v5
      Standard_D16as_v5
      Standard_D32as_v5
      Standard_D48as_v5
      Standard_D64as_v5
      Standard_D96as_v5
      Standard_D2ads_v5
      Standard_D4ads_v5
      Standard_D8ads_v5
      Standard_D16ads_v5
      Standard_D32ads_v5
      Standard_D48ads_v5
      Standard_D64ads_v5
      Standard_D96ads_v5
      Standard_DC2as_v5
      Standard_DC4as_v5
      Standard_DC8as_v5
      Standard_DC16as_v5
      Standard_DC32as_v5
      Standard_DC48as_v5
      Standard_DC64as_v5
      Standard_DC96as_v5
      Standard_DC2ads_v5
      Standard_DC4ads_v5
      Standard_DC8ads_v5
      Standard_DC16ads_v5
      Standard_DC32ads_v5
      Standard_DC48ads_v5
      Standard_DC64ads_v5
      Standard_DC96ads_v5
      Standard_DC4as_cc_v5
      Standard_DC8as_cc_v5
      Standard_DC16as_cc_v5
      Standard_DC32as_cc_v5
      Standard_DC48as_cc_v5
      Standard_DC64as_cc_v5
      Standard_DC96as_cc_v5
      Standard_DC4ads_cc_v5
      Standard_DC8ads_cc_v5
      Standard_DC16ads_cc_v5
      Standard_DC32ads_cc_v5
      Standard_DC48ads_cc_v5
      Standard_DC64ads_cc_v5
      Standard_DC96ads_cc_v5
      Standard_DC2es_v5
      Standard_DC4es_v5
      Standard_DC8es_v5
      Standard_DC16es_v5
      Standard_DC32es_v5
      Standard_DC48es_v5
      Standard_DC64es_v5
      Standard_DC96es_v5
      Standard_DC2eds_v5
      Standard_DC4eds_v5
      Standard_DC8eds_v5
      Standard_DC16eds_v5
      Standard_DC32eds_v5
      Standard_DC48eds_v5
      Standard_DC64eds_v5
      Standard_DC96eds_v5
      Standard_D2ps_v5
      Standard_D4ps_v5
      Standard_D8ps_v5
      Standard_D16ps_v5
      Standard_D32ps_v5
      Standard_D48ps_v5
      Standard_D64ps_v5
      Standard_D2pds_v5
      Standard_D4pds_v5
      Standard_D8pds_v5
      Standard_D16pds_v5
      Standard_D32pds_v5
      Standard_D48pds_v5
      Standard_D64pds_v5
      Standard_D2pls_v5
      Standard_D4pls_v5
      Standard_D8pls_v5
      Standard_D16pls_v5
      Standard_D32pls_v5
      Standard_D48pls_v5
      Standard_D64pls_v5
      Standard_D2plds_v5
      Standard_D4plds_v5
      Standard_D8plds_v5
      Standard_D16plds_v5
      Standard_D32plds_v5
      Standard_D48plds_v5
      Standard_D64plds_v5
      Standard_B2ts_v2
      Standard_B2ls_v2
      Standard_B2s_v2
      Standard_B4ls_v2
      Standard_B4s_v2
      Standard_B8ls_v2
      Standard_B8s_v2
      Standard_B16ls_v2
      Standard_B16s_v2
      Standard_B32ls_v2
      Standard_B32s_v2
      Standard_B2ats_v2
      Standard_B2als_v2
      Standard_B2as_v2
      Standard_B4als_v2
      Standard_B4as_v2
      Standard_B8als_v2
      Standard_B8as_v2
      Standard_B16als_v2
      Standard_B16as_v2
      Standard_B32als_v2
      Standard_B32as_v2
      Standard_B2pts_v2
      Standard_B2pls_v2
      Standard_B2ps_v2
      Standard_B4pls_v2
      Standard_B4ps_v2
      Standard_B8pls_v2
      Standard_B8ps_v2
      Standard_B16pls_v2
      Standard_B16ps_v2
      Standard_DC1s_v3
      Standard_DC2s_v3
      Standard_DC4s_v3
      Standard_DC8s_v3
      Standard_DC16s_v3
      Standard_DC24s_v3
      Standard_DC32s_v3
      Standard_DC48s_v3
      Standard_DC1ds_v3
      Standard_DC2ds_v3
      Standard_DC4ds_v3
      Standard_DC8ds_v3
      Standard_DC16ds_v3
      Standard_DC24ds_v3
      Standard_DC32ds_v3
      Standard_DC48ds_v3
    ],
    compute_optimized: %w[
      Standard_F2s_v2
      Standard_F4s_v2
      Standard_F8s_v2
      Standard_F16s_v2
      Standard_F32s_v2
      Standard_F48s_v2
      Standard_F64s_v2
      Standard_F72s_v2
      Standard_F1
      Standard_F2
      Standard_F4
      Standard_F8
      Standard_F16
      Standard_F1s
      Standard_F2s
      Standard_F4s
      Standard_F8s
      Standard_F16s
      Standard_F2als_v6
      Standard_F4als_v6
      Standard_F8als_v6
      Standard_F16als_v6
      Standard_F32als_v6
      Standard_F48als_v6
      Standard_F64als_v6
      Standard_F2as_v6
      Standard_F4as_v6
      Standard_F8as_v6
      Standard_F16as_v6
      Standard_F32as_v6
      Standard_F48as_v6
      Standard_F64as_v6
      Standard_F2ams_v6
      Standard_F4ams_v6
      Standard_F8ams_v6
      Standard_F16ams_v6
      Standard_F32ams_v6
      Standard_F48ams_v6
      Standard_F64ams_v6
      Standard_FX4mds
      Standard_FX12mds
      Standard_FX24mds
      Standard_FX36mds
      Standard_FX48mds
    ],
    memory_optimized: %w[
      Standard_D11_v2
      Standard_D12_v2
      Standard_D13_v2
      Standard_D14_v2
      Standard_D15_v2
      Standard_DS11_v2
      Standard_DS12_v2
      Standard_DS13_v2
      Standard_DS14_v2
      Standard_DS15_v2
      Standard_E2_v3
      Standard_E4_v3
      Standard_E8_v3
      Standard_E16_v3
      Standard_E20_v3
      Standard_E32_v3
      Standard_E48_v3
      Standard_E64_v3
      Standard_E64i_v3
      Standard_E2s_v3
      Standard_E4s_v3
      Standard_E8s_v3
      Standard_E16s_v3
      Standard_E20s_v3
      Standard_E32s_v3
      Standard_E48s_v3
      Standard_E64s_v3
      Standard_E64is_v3
      Standard_E2a_v4
      Standard_E4a_v4
      Standard_E8a_v4
      Standard_E16a_v4
      Standard_E20a_v4
      Standard_E32a_v4
      Standard_E48a_v4
      Standard_E64a_v4
      Standard_E96a_v4
      Standard_E2as_v4
      Standard_E4as_v4
      Standard_E8as_v4
      Standard_E16as_v4
      Standard_E20as_v4
      Standard_E32as_v4
      Standard_E48as_v4
      Standard_E64as_v4
      Standard_E96as_v4
      Standard_E2d_v4
      Standard_E4d_v4
      Standard_E8d_v4
      Standard_E16d_v4
      Standard_E20d_v4
      Standard_E32d_v4
      Standard_E48d_v4
      Standard_E64d_v4
      Standard_E2ds_v4
      Standard_E4ds_v4
      Standard_E8ds_v4
      Standard_E16ds_v4
      Standard_E20ds_v4
      Standard_E32ds_v4
      Standard_E48ds_v4
      Standard_E64ds_v4
      Standard_E80ids_v4
      Standard_E2_v4
      Standard_E4_v4
      Standard_E8_v4
      Standard_E16_v4
      Standard_E20_v4
      Standard_E32_v4
      Standard_E48_v4
      Standard_E64_v4
      Standard_E2s_v4
      Standard_E4s_v4
      Standard_E8s_v4
      Standard_E16s_v4
      Standard_E20s_v4
      Standard_E32s_v4
      Standard_E48s_v4
      Standard_E64s_v4
      Standard_E80is_v4
      Standard_M8ms
      Standard_M16ms
      Standard_M32ts
      Standard_M32ls
      Standard_M32ms
      Standard_M64s
      Standard_M64ls
      Standard_M64ms
      Standard_M128s
      Standard_M128ms
      Standard_M64
      Standard_M64m
      Standard_M128
      Standard_M128m
      Standard_M32ms_v2
      Standard_M64s_v2
      Standard_M64ms_v2
      Standard_M128s_v2
      Standard_M128ms_v2
      Standard_M192is_v2
      Standard_M192ims_v2
      Standard_M32dms_v2
      Standard_M64ds_v2
      Standard_M64dms_v2
      Standard_M128ds_v2
      Standard_M128dms_v2
      Standard_M192ids_v2
      Standard_M192idms_v2
      Standard_M208ms_v2
      Standard_M208s_v2
      Standard_M416ms_v2
      Standard_M416s_v2
      Standard_E2as_v6
      Standard_E4as_v6
      Standard_E8as_v6
      Standard_E16as_v6
      Standard_E20as_v6
      Standard_E32as_v6
      Standard_E48as_v6
      Standard_E64as_v6
      Standard_E96as_v6
      Standard_E2ads_v6
      Standard_E4ads_v6
      Standard_E8ads_v6
      Standard_E16ads_v6
      Standard_E20ads_v6
      Standard_E32ads_v6
      Standard_E48ads_v6
      Standard_E64ads_v6
      Standard_E96ads_v6
      Standard_E2_v5
      Standard_E4_v5
      Standard_E8_v5
      Standard_E16_v5
      Standard_E20_v5
      Standard_E32_v5
      Standard_E48_v5
      Standard_E64_v5
      Standard_E96_v5
      Standard_E104i_v5
      Standard_E2s_v5
      Standard_E4s_v5
      Standard_E8s_v5
      Standard_E16s_v5
      Standard_E20s_v5
      Standard_E32s_v5
      Standard_E48s_v5
      Standard_E64s_v5
      Standard_E96s_v5
      Standard_E104is_v5
      Standard_E2d_v5
      Standard_E4d_v5
      Standard_E8d_v5
      Standard_E16d_v5
      Standard_E20d_v5
      Standard_E32d_v5
      Standard_E48d_v5
      Standard_E64d_v5
      Standard_E96d_v5
      Standard_E104id_v5
      Standard_E2ds_v5
      Standard_E4ds_v5
      Standard_E8ds_v5
      Standard_E16ds_v5
      Standard_E20ds_v5
      Standard_E32ds_v5
      Standard_E48ds_v5
      Standard_E64ds_v5
      Standard_E96ds_v5
      Standard_E104ids_v5
      Standard_E2bds_v5
      Standard_E4bds_v5
      Standard_E8bds_v5
      Standard_E16bds_v5
      Standard_E32bds_v5
      Standard_E48bds_v5
      Standard_E64bds_v5
      Standard_E96bds_v5
      Standard_E2bds_v5
      Standard_E4bds_v5
      Standard_E8bds_v5
      Standard_E16bds_v5
      Standard_E32bds_v5
      Standard_E48bds_v5
      Standard_E64bds_v5
      Standard_E96bds_v5
      Standard_E112ibds_v5
      Standard_E2bs_v5
      Standard_E4bs_v5
      Standard_E8bs_v5
      Standard_E16bs_v5
      Standard_E32bs_v5
      Standard_E48bs_v5
      Standard_E64bs_v5
      Standard_E96bs_v5
      Standard_E2bs_v5
      Standard_E4bs_v5
      Standard_E8bs_v5
      Standard_E16bs_v5
      Standard_E32bs_v5
      Standard_E48bs_v5
      Standard_E64bs_v5
      Standard_E96bs_v5
      Standard_E112ibds_v5
      Standard_E2as_v5
      Standard_E8as_v5
      Standard_E16as_v5
      Standard_E20as_v5
      Standard_E32as_v5
      Standard_E48as_v5
      Standard_E64as_v5
      Standard_E96as_v5
      Standard_E112ias_v5
      Standard_E2ads_v5
      Standard_E4ads_v5
      Standard_E8ads_v5
      Standard_E16ads_v5
      Standard_E20ads_v5
      Standard_E32ads_v5
      Standard_E48ads_v5
      Standard_E64ads_v5
      Standard_E96ads_v5
      Standard_E112iads_v5
      Standard_EC2as_v5
      Standard_EC4as_v5
      Standard_EC8as_v5
      Standard_EC16as_v5
      Standard_EC20as_v5
      Standard_EC32as_v5
      Standard_EC48as_v5
      Standard_EC64as_v5
      Standard_EC96as_v5
      Standard_EC2ads_v5
      Standard_EC4ads_v5
      Standard_EC8ads_v5
      Standard_EC16ads_v5
      Standard_EC20ads_v5
      Standard_EC32ads_v5
      Standard_EC48ads_v5
      Standard_EC64ads_v5
      Standard_EC96ads_v5
      Standard_EC4as_cc_v5
      Standard_EC8as_cc_v5
      Standard_EC16as_cc_v5
      Standard_EC20as_cc_v5
      Standard_EC32as_cc_v5
      Standard_EC48as_cc_v5
      Standard_EC64as_cc_v5
      Standard_EC96as_cc_v5
      Standard_EC4ads_cc_v5
      Standard_EC8ads_cc_v5
      Standard_EC16ads_cc_v5
      Standard_EC20ads_cc_v5
      Standard_EC32ads_cc_v5
      Standard_EC48ads_cc_v5
      Standard_EC64ads_cc_v5
      Standard_EC96ads_cc_v5
      Standard_EC2es_v5
      Standard_EC4es_v5
      Standard_EC8es_v5
      Standard_EC16es_v5
      Standard_EC32es_v5
      Standard_EC48es_v5
      Standard_EC64es_v5
      Standard_EC128es_v5
      Standard_EC2eds_v5
      Standard_EC4eds_v5
      Standard_EC8eds_v5
      Standard_EC16eds_v5
      Standard_EC32eds_v5
      Standard_EC48eds_v5
      Standard_EC64eds_v5
      Standard_EC128eds_v5
      Standard_E2ps_v5
      Standard_E4ps_v5
      Standard_E8ps_v5
      Standard_E16ps_v5
      Standard_E20ps_v5
      Standard_E32ps_v5
      Standard_E2pds_v5
      Standard_E4pds_v5
      Standard_E8pds_v5
      Standard_E16pds_v5
      Standard_E20pds_v5
      Standard_E32pds_v5
      Standard_M12s_v3
      Standard_M24s_v3
      Standard_M48s_1_v3
      Standard_M96s_1_v3
      Standard_M96s_2_v3
      Standard_M176s_3_v3
      Standard_M176s_4_v3
      Standard_M12ds_v3
      Standard_M24ds_v3
      Standard_M48ds_1_v3
      Standard_M96ds_1_v3
      Standard_M96ds_2_v3
      Standard_M176ds_3_v3
      Standard_M176ds_4_v3

    ],
    storage_optimized: %w[
      Standard_L8s_v2
      Standard_L16s_v2
      Standard_L32s_v2
      Standard_L48s_v2
      Standard_L64s_v2
      Standard_L80s_v2
      Standard_L8s_v3
      Standard_L16s_v3
      Standard_L32s_v3
      Standard_L48s_v3
      Standard_L64s_v3
      Standard_L80s_v3
      Standard_L8as_v3
      Standard_L16as_v3
      Standard_L32as_v3
      Standard_L48as_v3
      Standard_L64as_v3
      Standard_L80as_v3
    ],
    gpu_accelerated: %w[],
    high_performance_compute: %w[]
  }

TAG_EVENT_TYPES = ["CreateTags","DeleteTags","AddTags","RemoveTags","CreateOrUpdateTags","AddTagsToResource","RemoveTagsFromResource", "PutMetricAlarm"]
ROLE_ARNS = ["arn:aws:iam::702574401249:role/Ec2CodeDeploy", "arn:aws:iam::336101051063:role/Ec2CodeDeploy", "arn:aws:iam::305775191159:role/Ec2CodeDeploy", "arn:aws:iam::347925220829:role/Ec2CodeDeploy", "arn:aws:iam::068706686347:role/Ec2CodeDeploy", "arn:aws:iam::647183662077:role/Ec2CodeDeploy", "arn:aws:iam::095001120560:role/Ec2CodeDeploy", "arn:aws:iam::707082674943:role/Ec2CodeDeploy", "arn:aws:iam::388760430404:role/Ec2CodeDeploy"]
# Below resource are considered for the idle condition
RESOURCE_FOR_IDLE_CONDITION = ['Azure::Resource::Compute::VirtualMachine',
  'Azure::Resource::Database::MySQL::Server',
  'Azure::Resource::Database::MariaDB::Server',
  'Azure::Resource::Database::PostgreSQL::Server',
  'Azure::Resource::Database::SQL::DB',
  'Azure::Resource::Compute::Disk',
  'Azure::Resource::Network::LoadBalancer']

AZURE_LOCATION_CODES = {
  "australiaeast": 'Australia East',
  "australiasoutheast": 'Australia Southeast',
  "australiacentral": 'Australia Central',
  "australiacentral2": 'Australia Central 2',
  "brazilsouth": 'Brazil South',
  "canadacentral": 'Canada Central',
  "canadaeast": 'Canada East',
  "centralindia": 'Central India',
  "centralus": 'Central US',
  "eastasia": 'East Asia',
  "eastus": 'East US',
  "eastus2": 'East US 2',
  "francecentral": 'France Central',
  "japaneast": 'Japan East',
  "japanwest": 'Japan West',
  "koreacentral": 'Korea Central',
  "koreasouth": 'Korea South',
  "northcentralus": 'North Central US',
  "northeurope": 'North Europe',
  "southafricanorth": 'South Africa North',
  "southafricawest": 'South Africa West',
  "southcentralus": 'South Central US',
  "southeastasia": 'Southeast Asia',
  "southindia": 'South India',
  "uksouth": 'UK South',
  "ukwest": 'UK West',
  "westcentralus": 'West Central US',
  "westeurope": 'West Europe',
  "westindia": 'West India',
  "westus": 'West US',
  "westus2": 'West US 2',
  "germanywestcentral": 'Germany West Central',
  "norwayeast": 'Norway East',
  "switzerlandnorth": 'Switzerland North',
  "uaenorth": 'UAE North'}.freeze

  # Adapter mapping
  ADP_AWS = 'Adapters::AWS'
  ADP_AZURE = 'Adapters::Azure'
  ADP_GCP = 'Adapters::GCP'

  SERVICE_ADVISER_CONFIG_TYPE = {
    aws: {
      idle: %w[ec2 load_balancer rds volume rds_snapshot volume_snapshot ami application_load_balancer network_load_balancer],
      unoptimized: %w[ec2]
    },
    azure: {
      idle: %w[virtual_machine disk load_balancer mysql postgresql mariadb sql_dtu sql_vcore elastic_pool_vcore elastic_pool_dtu app_service_plan snapshot blob aks],
      unoptimized: %w[virtual_machine_rightsizing sql_db_rightsizing virtual_machine_ahub sql_db_ahub elastic_pool_ahub]
    }
  }.freeze

  AZURE_SERVICE_MAPPING = {
    'idle_lbs' => 'Idle Load Balancers',
    'idle_databases' => 'Idle Databases',
    'idle_vm' => 'Idle VM (Running)',
    'idle_stopped_vm' => 'Idle VM (Stopped)',
    'idle_disks' => 'Idle Disks',
    'unassociated_lbs' => 'Unassociated Load Balancers',
    'unassociated_public_ips' => 'Unassociated Public IPs',
    'unattached_disks' => 'Unattached Disks',
    'unused_snapshots' => 'Unused Snapshots',
    'idle_elastic_pools' => 'Idle Elastic Pools',
    'idle_blob_services' => 'Idle Blob Services',
    'vm_right_sizings' => 'Right Sizing (VM)',
    'sqldb_rightsizing' => 'Right Sizing (SQL DB)',
    'hybrid_benefit_vm' => 'Hybrid Benefit (VM)',
    'hybrid_benefit_sql_db' => 'Hybrid Benefit (SQL DB)',
    'hybrid_benefit_elastic_pool' => 'Hybrid Benefit (Elastic Pool)',
    'idle_aks' => 'Idle AKS',
    'idle_app_service_plans' => 'Idle App Service Plans',
    'unused_app_service_plans' => 'Unused App Service Plans'
  }.freeze

  HOSTED_REGIONS = { 
    "apse2" => "Asia Pacific (Sydney)",
    "cac1" => "Canada (Central)",
    "ff" => "EU (Frankfurt)",
    "euw1" => "EU (Ireland)",
    "apse1" => "Asia Pacific (Singapore)",
    "euw2" => "EU (London)"
  }

  DEFAULT_REGIONS = {
    "dev" => "US East (Ohio)",
    "staging" => "US West (Oregon)",
    "production" => "US West (Oregon)"
  }

  SUSPECIOUS_EMAILS = %w[@kjjf]

  SPOT_INSTANCES_COST_REGION_MAP = {
  'ap-northeast-1' => 'apac-tokyo',
  'af-south-1' => 'af-south-1',
  'ap-east-1' => 'ap-east-1',
  'ap-south-1' => 'ap-south-1',
  'ap-northeast-2' => 'ap-northeast-2',
  'ca-central-1' => 'ca-central-1',
  'eu-central-1' => 'eu-central-1',
  'eu-west-1' => 'eu-ireland',
  'eu-west-2' => 'eu-west-2',
  'eu-south-1' => 'eu-south-1',
  'eu-west-3' => 'eu-west-3',
  'eu-north-1' => 'eu-north-1',
  'me-south-1' => 'me-south-1',
  'sa-east-1' => 'sa-east-1',
  'us-east-2' => 'us-east-2',
  'us-west-2' => 'us-west-2',
  'ap-southeast-1' => 'apac-sin',
  'ap-southeast-2' => 'apac-syd',
  'us-east-1' => 'us-east',
  'us-west-1' => 'us-west',
  }.freeze


  # TODO: Need to remove below costing data and fetch from API
  # once AWS Add support for US gov in spot pricing api.
  # Spot price API: https://spot-price.s3.amazonaws.com/spot.js

PROVIDER_CONFIG = {
  "AWS": {
    "charges" => {
                "general_on_demand_usage": true,
                "upfront_reservation_charges": true,
                "recurring_reservation_fees": true,
                "covered_reservation_usage": true,
                "upfront_saving_plan_fees": true,
                "recurring_savings_plan_fees": true,
                "covered_savings_plan_usage": true,
                "out_of_cycle_subscription_fees": true,
                "aws_support_fees": true,
                "tax": true
    },
    "credits_and_refunds" => {
                            "general_refunds": true,
                            "general_credits": true,
                            "edp_discounts": true,
                            "spp_discounts": true,
                            "tax": true,
                            "savings_plan_negation": true
    },
    "metrics": %w[blended unblended amortised credit reservation_charge tax saving_plan_savings saving_plan_hourly usage_quantity
                  reserved_hours on_demand_hours refund margin_cost net_cost discount_cost customer_cost spp_discount
                  excluded_ri_benefit excluded_sp_benefit bundled_discount net_allocated_cost allocated_cost drained_cost fixed_margin fixed_discount service_type_margin service_type_discount usage_hour_margin usage_hour_discount amortized_with_saving_plan net_amortized_cost net_unblended_cost percentage_of_spend_billing_entity_margin percentage_of_spend_billing_entity_discount percentage_of_spend_item_description_margin percentage_of_spend_item_description_discount percentage_of_spend_usage_type_margin percentage_of_spend_usage_type_discount percentage_of_spend_operation_margin percentage_of_spend_operation_discount percentage_of_spend_charge_type_margin percentage_of_spend_charge_type_discount usage_quantity_multiplier usage_quantity_multiplier_item_description_margin usage_quantity_multiplier_usage_type_margin usage_quantity_multiplier_charge_type_margin usage_quantity_multiplier_operation_margin],
     "selected_metric": 'unblended'
  },
  "Azure": {
    "charges" => {
      "is_usage": true,
      "is_marketplace": true,
      "is_purchase": true
    },
    "refunds" => {
      "is_refund": true,
      "is_tax_charge": true
    },
    "credits" => {
      "is_credit": true
    },
    "margins_discounts" => {
      "is_margin": false,
      "is_discount": false
    },
    "metrics" => %w[cost credit refund customer_cost margin_cost net_cost discount_cost usage_quantity net_allocated_cost allocated_cost drained_cost amortised],
    "selected_metric" => 'cost'
  },
  "GCP": {
    "charges" => {
      "is_usage": true,
      "is_tax_charge": true
    },
    "refunds" => {
      "is_refund": true,
      "is_tax_refund": true
    },
    "credits" => {
      "is_credit": true
    },
    "margins_discounts" => {
      "is_reseller_margin": true,
      "is_partner_discount": true,
      "is_cud_discount": true
    },
    "metrics" => %w[cost customer_cost partner_discount reseller_margin margin_cost net_cost discount_cost cud_discount],
    "selected_metric" => 'cost'
  },
  "VMware": {
    "charges" => {
      "is_usage": true
    },
    "refunds" => {
      "is_refund": true,
      "is_tax_charge": true
    },
    "credits" => {
      "is_credit": true
    },
    "margins_discounts" => {
      "is_margin": false,
      "is_discount": false
    },
    "metrics" => %w[cost margin_cost net_cost discount_cost uptime_hours],
    "selected_metric" => 'cost'
  },
  "Azure_csp": {
    "margins_discounts" => {
      "is_margin": true,
      "is_discount": true
    },
    "metrics" => %w[cost credit refund customer_cost net_cost on_demand_charges_discount_cost reservations_charges_discount_cost marketplace_charges_discount_cost office_based_purchases_discount_cost on_demand_charges_margin_cost reservations_charges_margin_cost office_based_purchases_margin_cost marketplace_charges_margin_cost pec usage_quantity net_allocated_cost allocated_cost drained_cost],
    "selected_metric" => 'cost'
  }
}.freeze

PROVIDER_CONFIG_CHILD_ORG = {
  "AWS": {
    "charges" => {
                "general_on_demand_usage": false,
                "upfront_reservation_charges": false,
                "recurring_reservation_fees": false,
                "covered_reservation_usage": false,
                "upfront_saving_plan_fees": false,
                "recurring_savings_plan_fees": false,
                "covered_savings_plan_usage": false,
                "out_of_cycle_subscription_fees": false,
                "aws_support_fees": false,
                "tax": false
    },
    "credits_and_refunds" => {
                            "general_refunds": false,
                            "general_credits": false,
                            "edp_discounts": false,
                            "spp_discounts": false,
                            "tax": false,
                            "savings_plan_negation": false
    },
    "metrics": %w[net_cost],
    "selected_metric" => 'net_cost'
  },
  "Azure": {
    "charges" => {
      "is_usage": false,
      "is_marketplace": false,
      "is_purchase": false
    },
    "refunds" => {
      "is_refund": false,
      "is_tax_charge": false
    },
    "credits" => {
      "is_credit": false
    },
    "margins_discounts" => {
      "is_margin": false,
      "is_discount": false
    },
    "metrics" => %w[net_cost],
    "selected_metric" => 'net_cost'
  },
  "GCP": {
    "charges" => {
      "is_usage": false,
      "is_tax_charge": false
    },
    "refunds" => {
      "is_refund": false,
      "is_tax_refund": false
    },
    "credits" => {
      "is_credit": false
    },
    "margins_discounts" => {
      "is_reseller_margin": false,
      "is_partner_discount": false,
      "is_cud_discount": false
    },
    "metrics" => %w[net_cost],
    "selected_metric" => 'net_cost'
  },
  "VMware": {
    "charges" => {
      "is_usage": false
    },
    "refunds" => {
      "is_refund": false,
      "is_tax_charge": false
    },
    "credits" => {
      "is_credit": false
    },
    "margins_discounts" => {
      "is_margin": false,
      "is_discount": false
    },
    "metrics" => %w[net_cost],
    "selected_metric" => 'net_cost'
  },
  "Azure_csp": {
    "margins_discounts" => {
      "is_margin": false,
      "is_discount": false
    },
    "metrics" => %w[net_cost],
    "selected_metric" => 'net_cost'
  }
}.freeze


PROVIDER_CONFIG_RESELLER_CHILD_ORG = {
  "AWS": {
    "charges" => {
                "general_on_demand_usage": false,
                "upfront_reservation_charges": false,
                "recurring_reservation_fees": false,
                "covered_reservation_usage": false,
                "upfront_saving_plan_fees": false,
                "recurring_savings_plan_fees": false,
                "covered_savings_plan_usage": false,
                "out_of_cycle_subscription_fees": false,
                "aws_support_fees": false,
                "tax": false
    },
    "credits_and_refunds" => {
                            "general_refunds": false,
                            "general_credits": false,
                            "edp_discounts": false,
                            "spp_discounts": false,
                            "tax": false,
                            "savings_plan_negation": false
    },
    "metrics": %w[reseller_org_net_cost],
    "selected_metric" => 'reseller_org_net_cost'
  },
  "Azure": {
    "charges" => {
      "is_usage": false,
      "is_marketplace": false,
      "is_purchase": false
    },
    "refunds" => {
      "is_refund": false,
      "is_tax_charge": false
    },
    "credits" => {
      "is_credit": false
    },
    "margins_discounts" => {
      "is_margin": false,
      "is_discount": false
    },
    "metrics" => %w[reseller_org_net_cost],
    "selected_metric" => 'reseller_org_net_cost'
  },
  "GCP": {
    "charges" => {
      "is_usage": false,
      "is_tax_charge": false
    },
    "refunds" => {
      "is_refund": false,
      "is_tax_refund": false
    },
    "credits" => {
      "is_credit": false
    },
    "margins_discounts" => {
      "is_reseller_margin": false,
      "is_partner_discount": false
    },
    "metrics" => %w[reseller_org_net_cost],
    "selected_metric" => 'reseller_org_net_cost'
  },
  "VMware": {
    "charges" => {
      "is_usage": false
    },
    "refunds" => {
      "is_refund": false,
      "is_tax_charge": false
    },
    "credits" => {
      "is_credit": false
    },
    "margins_discounts" => {
      "is_margin": false,
      "is_discount": false
    },
    "metrics" => %w[reseller_org_net_cost],
    "selected_metric" => 'reseller_org_net_cost'
  },
  "Azure_csp": {
    "margins_discounts" => {
      "is_margin": false,
      "is_discount": false
    },
    "metrics" => %w[reseller_org_net_cost],
    "selected_metric" => 'reseller_org_net_cost'
  }
}.freeze

  US_GOV_EAST_1_SPOT_PRICING = {
  "m5.large"=>0.0,
  "m5.xlarge"=>0.0,
  "m5.2xlarge"=>0.0,
  "m5.4xlarge"=>0.0,
  "m5.8xlarge"=>0.0,
  "m5.12xlarge"=>0.0,
  "m5.16xlarge"=>0.0,
  "m5.24xlarge"=>0.0,
  "m5a.large"=>0.0,
  "m5a.xlarge"=>0.0,
  "m5a.2xlarge"=>0.0,
  "m5a.4xlarge"=>0.0,
  "m5a.8xlarge"=>0.0,
  "m5a.12xlarge"=>0.0,
  "m5a.16xlarge"=>0.0,
  "m5a.24xlarge"=>0.0,
  "m5d.large"=>0.0,
  "m5d.xlarge"=>0.0,
  "m5d.2xlarge"=>0.0,
  "m5d.4xlarge"=>0.0,
  "m5d.8xlarge"=>0.0,
  "m5d.12xlarge"=>0.0,
  "m5d.16xlarge"=>0.0,
  "m5d.24xlarge"=>0.0,
  "m5d.metal"=>0.0,
  "m5dn.large"=>0.0,
  "m5dn.xlarge"=>0.0,
  "m5dn.2xlarge"=>0.0,
  "m5dn.4xlarge"=>0.0,
  "m5dn.8xlarge"=>0.0,
  "m5dn.12xlarge"=>0.0,
  "m5dn.16xlarge"=>0.0,
  "m5dn.metal"=>0.0,
  "m5dn.24xlarge"=>0.0,
  "m5n.large"=>0.0,
  "m5n.xlarge"=>0.0,
  "m5n.2xlarge"=>0.0,
  "m5n.4xlarge"=>0.0,
  "m5n.8xlarge"=>0.0,
  "m5n.12xlarge"=>0.0,
  "m5n.16xlarge"=>0.0,
  "m5n.24xlarge"=>0.0,
  "m5n.metal"=>0.0,
  "m6g.medium"=>0.0,
  "m6g.large"=>0.0,
  "m6g.xlarge"=>0.0,
  "m6g.2xlarge"=>0.0,
  "m6g.4xlarge"=>0.0,
  "m6g.8xlarge"=>0.0,
  "m6g.12xlarge"=>0.0,
  "m6g.16xlarge"=>0.0,
  "m6g.metal"=>0.0,
  "t3.large"=>0.0,
  "t3.nano"=>0.0,
  "t3.small"=>0.0,
  "t3.medium"=>0.0,
  "t3.micro"=>0.0,
  "t3.xlarge"=>0.0,
  "t3.2xlarge"=>0.0,
  "t3a.small"=>0.0,
  "t3a.micro"=>0.0,
  "t3a.nano"=>0.0,
  "t3a.medium"=>0.0,
  "t3a.large"=>0.0,
  "t3a.xlarge"=>0.0,
  "t3a.2xlarge"=>0.0,
  "t4g.medium"=>0.0,
  "t4g.micro"=>0.0,
  "t4g.nano"=>0.0,
  "t4g.large"=>0.0,
  "t4g.small"=>0.0,
  "t4g.xlarge"=>0.0,
  "t4g.2xlarge"=>0.0,
  "c5.large"=>0.0,
  "c5.xlarge"=>0.0,
  "c5.2xlarge"=>0.0,
  "c5.4xlarge"=>0.0,
  "c5.9xlarge"=>0.0,
  "c5.12xlarge"=>0.0,
  "c5.18xlarge"=>0.0,
  "c5.metal"=>0.0,
  "c5.24xlarge"=>0.0,
  "c5a.large"=>0.0,
  "c5a.xlarge"=>0.0,
  "c5a.2xlarge"=>0.0,
  "c5a.4xlarge"=>0.0,
  "c5a.8xlarge"=>0.0,
  "c5a.12xlarge"=>0.0,
  "c5a.16xlarge"=>0.0,
  "c5a.24xlarge"=>0.0,
  "c5d.large"=>0.0,
  "c5d.xlarge"=>0.0,
  "c5d.2xlarge"=>0.0,
  "c5d.4xlarge"=>0.0,
  "c5d.9xlarge"=>0.0,
  "c5d.18xlarge"=>0.0,
  "c5n.large"=>0.0,
  "c5n.xlarge"=>0.0,
  "c5n.2xlarge"=>0.0,
  "c5n.4xlarge"=>0.0,
  "c5n.9xlarge"=>0.0,
  "c5n.metal"=>0.0,
  "c5n.18xlarge"=>0.0,
  "c6g.medium"=>0.0,
  "c6g.large"=>0.0,
  "c6g.xlarge"=>0.0,
  "c6g.2xlarge"=>0.0,
  "c6g.4xlarge"=>0.0,
  "c6g.8xlarge"=>0.0,
  "c6g.12xlarge"=>0.0,
  "c6g.metal"=>0.0,
  "c6g.16xlarge"=>0.0,
  "g4dn.xlarge"=>0.0,
  "g4dn.2xlarge"=>0.0,
  "g4dn.4xlarge"=>0.0,
  "g4dn.8xlarge"=>0.0,
  "g4dn.12xlarge"=>0.0,
  "g4dn.16xlarge"=>0.0,
  "inf1.xlarge"=>0.0,
  "inf1.2xlarge"=>0.0,
  "inf1.6xlarge"=>0.0,
  "inf1.24xlarge"=>0.0,
  "p3dn.24xlarge"=>0.0,
  "r5.large"=>0.0,
  "r5.xlarge"=>0.0,
  "r5.2xlarge"=>0.0,
  "r5.4xlarge"=>0.0,
  "r5.8xlarge"=>0.0,
  "r5.12xlarge"=>0.0,
  "r5.16xlarge"=>0.0,
  "r5.24xlarge"=>0.0,
  "r5.metal"=>0.0,
  "r5a.large"=>0.0,
  "r5a.xlarge"=>0.0,
  "r5a.2xlarge"=>0.0,
  "r5a.4xlarge"=>0.0,
  "r5a.8xlarge"=>0.0,
  "r5a.12xlarge"=>0.0,
  "r5a.16xlarge"=>0.0,
  "r5a.24xlarge"=>0.0,
  "r5d.large"=>0.0,
  "r5d.xlarge"=>0.0,
  "r5d.2xlarge"=>0.0,
  "r5d.4xlarge"=>0.0,
  "r5d.8xlarge"=>0.0,
  "r5d.12xlarge"=>0.0,
  "r5d.16xlarge"=>0.0,
  "r5d.24xlarge"=>0.0,
  "r5d.metal"=>0.0,
  "r5dn.large"=>0.0,
  "r5dn.xlarge"=>0.0,
  "r5dn.2xlarge"=>0.0,
  "r5dn.4xlarge"=>0.0,
  "r5dn.8xlarge"=>0.0,
  "r5dn.12xlarge"=>0.0,
  "r5dn.16xlarge"=>0.0,
  "r5dn.metal"=>0.0,
  "r5dn.24xlarge"=>0.0,
  "r5n.large"=>0.0,
  "r5n.xlarge"=>0.0,
  "r5n.2xlarge"=>0.0,
  "r5n.4xlarge"=>0.0,
  "r5n.8xlarge"=>0.0,
  "r5n.12xlarge"=>0.0,
  "r5n.16xlarge"=>0.0,
  "r5n.24xlarge"=>0.0,
  "r5n.metal"=>0.0,
  "r6g.medium"=>0.0,
  "r6g.large"=>0.0,
  "r6g.xlarge"=>0.0,
  "r6g.2xlarge"=>0.0,
  "r6g.4xlarge"=>0.0,
  "r6g.8xlarge"=>0.0,
  "r6g.12xlarge"=>0.0,
  "r6g.metal"=>0.0,
  "r6g.16xlarge"=>0.0,
  "x1.16xlarge"=>0.0,
  "x1.32xlarge"=>0.0,
  "x1e.xlarge"=>0.0,
  "x1e.2xlarge"=>0.0,
  "x1e.4xlarge"=>0.0,
  "x1e.8xlarge"=>0.0,
  "x1e.16xlarge"=>0.0,
  "x1e.32xlarge"=>0.0,
  "i3.large"=>0.0,
  "i3.xlarge"=>0.0,
  "i3.2xlarge"=>0.0,
  "i3.4xlarge"=>0.0,
  "i3.8xlarge"=>0.0,
  "i3.16xlarge"=>0.0,
  "i3.metal"=>0.0,
  "i3en.large"=>0.0,
  "i3en.xlarge"=>0.0,
  "i3en.2xlarge"=>0.0,
  "i3en.3xlarge"=>0.0,
  "i3en.6xlarge"=>0.0,
  "i3en.12xlarge"=>0.0,
  "i3en.24xlarge"=>0.0,
  "i3en.metal" => 0.0
}.freeze



  US_GOV_WEST_1_SPOT_PRICING = {
  "m1.small"=>0.0,
  "m1.medium"=>0.0,
  "m1.large"=>0.0,
  "m1.xlarge"=>0.0,
  "m2.xlarge"=>0.0,
  "m2.2xlarge"=>0.0,
  "m2.4xlarge"=>0.0,
  "m3.medium"=>0.0,
  "m3.large"=>0.0,
  "m3.xlarge"=>0.0,
  "m3.2xlarge"=>0.0,
  "m4.large"=>0.0,
  "m4.xlarge"=>0.0,
  "m4.2xlarge"=>0.0,
  "m4.4xlarge"=>0.0,
  "m4.10xlarge"=>0.0,
  "m4.16xlarge"=>0.0,
  "m5.large"=>0.0,
  "m5.xlarge"=>0.0,
  "m5.2xlarge"=>0.0,
  "m5.4xlarge"=>0.0,
  "m5.8xlarge"=>0.0,
  "m5.12xlarge"=>0.0,
  "m5.16xlarge"=>0.0,
  "m5.24xlarge"=>0.0,
  "m5a.large"=>0.0,
  "m5a.xlarge"=>0.0,
  "m5a.2xlarge"=>0.0,
  "m5a.4xlarge"=>0.0,
  "m5a.8xlarge"=>0.0,
  "m5a.12xlarge"=>0.0,
  "m5a.16xlarge"=>0.0,
  "m5a.24xlarge"=>0.0,
  "m5ad.large"=>0.0,
  "m5ad.xlarge"=>0.0,
  "m5ad.2xlarge"=>0.0,
  "m5ad.4xlarge"=>0.0,
  "m5ad.8xlarge"=>0.0,
  "m5ad.12xlarge"=>0.0,
  "m5ad.16xlarge"=>0.0,
  "m5ad.24xlarge"=>0.0,
  "m5d.large"=>0.0,
  "m5d.xlarge"=>0.0,
  "m5d.2xlarge"=>0.0,
  "m5d.4xlarge"=>0.0,
  "m5d.24xlarge"=>0.0,
  "m5dn.large"=>0.0,
  "m5dn.xlarge"=>0.0,
  "m5dn.2xlarge"=>0.0,
  "m5dn.4xlarge"=>0.0,
  "m5dn.8xlarge"=>0.0,
  "m5dn.12xlarge"=>0.0,
  "m5dn.16xlarge"=>0.0,
  "m5dn.24xlarge"=>0.0,
  "m5n.large"=>0.0,
  "m5n.xlarge"=>0.0,
  "m5n.2xlarge"=>0.0,
  "m5n.4xlarge"=>0.0,
  "m5n.8xlarge"=>0.0,
  "m5n.12xlarge"=>0.0,
  "m5n.16xlarge"=>0.0,
  "m5n.24xlarge"=>0.0,
  "m6g.medium"=>0.0,
  "m6g.large"=>0.0,
  "m6g.xlarge"=>0.0,
  "m6g.2xlarge"=>0.0,
  "m6g.4xlarge"=>0.0,
  "m6g.8xlarge"=>0.0,
  "m6g.12xlarge"=>0.0,
  "m6g.16xlarge"=>0.0,
  "m6g.metal"=>0.0,
  "t1.micro"=>0.0,
  "t2.small"=>0.0,
  "t2.micro"=>0.0,
  "t2.large"=>0.0,
  "t2.medium"=>0.0,
  "t2.xlarge"=>0.0,
  "t2.2xlarge"=>0.0,
  "t3.large"=>0.0,
  "t3.nano"=>0.0,
  "t3.small"=>0.0,
  "t3.medium"=>0.0,
  "t3.micro"=>0.0,
  "t3.xlarge"=>0.0,
  "t3.2xlarge"=>0.0,
  "t3a.small"=>0.0,
  "t3a.micro"=>0.0,
  "t3a.nano"=>0.0,
  "t3a.medium"=>0.0,
  "t3a.large"=>0.0,
  "t3a.xlarge"=>0.0,
  "t3a.2xlarge"=>0.0,
  "t4g.medium"=>0.0,
  "t4g.micro"=>0.0,
  "t4g.nano"=>0.0,
  "t4g.large"=>0.0,
  "t4g.small"=>0.0,
  "t4g.xlarge"=>0.0,
  "t4g.2xlarge"=>0.0,
  "c1.xlarge"=>0.0,
  "c3.large"=>0.0,
  "c3.xlarge"=>0.0,
  "c3.2xlarge"=>0.0,
  "c3.4xlarge"=>0.0,
  "c3.8xlarge"=>0.0,
  "c4.large"=>0.0,
  "c4.xlarge"=>0.0,
  "c4.2xlarge"=>0.0,
  "c4.4xlarge"=>0.0,
  "c4.8xlarge"=>0.0,
  "c5.large"=>0.0,
  "c5.xlarge"=>0.0,
  "c5.2xlarge"=>0.0,
  "c5.4xlarge"=>0.0,
  "c5.9xlarge"=>0.0,
  "c5.12xlarge"=>0.0,
  "c5.18xlarge"=>0.0,
  "c5.metal"=>0.0,
  "c5.24xlarge"=>0.0,
  "c5a.large"=>0.0,
  "c5a.xlarge"=>0.0,
  "c5a.2xlarge"=>0.0,
  "c5a.4xlarge"=>0.0,
  "c5a.8xlarge"=>0.0,
  "c5a.12xlarge"=>0.0,
  "c5a.16xlarge"=>0.0,
  "c5a.24xlarge"=>0.0,
  "c5d.large"=>0.0,
  "c5d.xlarge"=>0.0,
  "c5d.2xlarge"=>0.0,
  "c5d.4xlarge"=>0.0,
  "c5d.9xlarge"=>0.0,
  "c5d.12xlarge"=>0.0,
  "c5d.18xlarge"=>0.0,
  "c5d.24xlarge"=>0.0,
  "c5d.metal"=>0.0,
  "c5n.large"=>0.0,
  "c5n.xlarge"=>0.0,
  "c5n.2xlarge"=>0.0,
  "c5n.4xlarge"=>0.0,
  "c5n.9xlarge"=>0.0,
  "c5n.metal"=>0.0,
  "c5n.18xlarge"=>0.0,
  "c6g.medium"=>0.0,
  "c6g.large"=>0.0,
  "c6g.xlarge"=>0.0,
  "c6g.2xlarge"=>0.0,
  "c6g.4xlarge"=>0.0,
  "c6g.8xlarge"=>0.0,
  "c6g.12xlarge"=>0.0,
  "c6g.metal"=>0.0,
  "c6g.16xlarge"=>0.0,
  "f1.2xlarge"=>0.0,
  "f1.4xlarge"=>0.0,
  "f1.16xlarge"=>0.0,
  "g3.4xlarge"=>0.0,
  "g3.8xlarge"=>0.0,
  "g3.16xlarge"=>0.0,
  "g4dn.xlarge"=>0.0,
  "g4dn.2xlarge"=>0.0,
  "g4dn.4xlarge"=>0.0,
  "g4dn.8xlarge"=>0.0,
  "g4dn.12xlarge"=>0.0,
  "g4dn.16xlarge"=>0.0,
  "inf1.xlarge"=>0.0,
  "inf1.2xlarge"=>0.0,
  "inf1.6xlarge"=>0.0,
  "inf1.24xlarge"=>0.0,
  "p2.xlarge"=>0.0,
  "p2.8xlarge"=>0.0,
  "p2.16xlarge"=>0.0,
  "p3.2xlarge"=>0.0,
  "p3.8xlarge"=>0.0,
  "p3.16xlarge"=>0.0,
  "p3dn.24xlarge"=>0.0,
  "r3.large"=>0.0,
  "r3.xlarge"=>0.0,
  "r3.2xlarge"=>0.0,
  "r3.4xlarge"=>0.0,
  "r3.8xlarge"=>0.0,
  "r4.large"=>0.0,
  "r4.xlarge"=>0.0,
  "r4.2xlarge"=>0.0,
  "r4.4xlarge"=>0.0,
  "r4.8xlarge"=>0.0,
  "r4.16xlarge"=>0.0,
  "r5.large"=>0.0,
  "r5.xlarge"=>0.0,
  "r5.2xlarge"=>0.0,
  "r5.4xlarge"=>0.0,
  "r5.8xlarge"=>0.0,
  "r5.12xlarge"=>0.0,
  "r5.16xlarge"=>0.0,
  "r5.24xlarge"=>0.0,
  "r5.metal"=>0.0,
  "r5a.large"=>0.0,
  "r5a.xlarge"=>0.0,
  "r5a.2xlarge"=>0.0,
  "r5a.4xlarge"=>0.0,
  "r5a.8xlarge"=>0.0,
  "r5a.12xlarge"=>0.0,
  "r5a.16xlarge"=>0.0,
  "r5a.24xlarge"=>0.0,
  "r5ad.large"=>0.0,
  "r5ad.xlarge"=>0.0,
  "r5ad.2xlarge"=>0.0,
  "r5ad.4xlarge"=>0.0,
  "r5ad.8xlarge"=>0.0,
  "r5ad.12xlarge"=>0.0,
  "r5ad.16xlarge"=>0.0,
  "r5ad.24xlarge"=>0.0,
  "r5d.large"=>0.0,
  "r5d.xlarge"=>0.0,
  "r5d.2xlarge"=>0.0,
  "r5d.4xlarge"=>0.0,
  "r5d.24xlarge"=>0.0,
  "r5d.metal"=>0.0,
  "r5dn.large"=>0.0,
  "r5dn.xlarge"=>0.0,
  "r5dn.2xlarge"=>0.0,
  "r5dn.4xlarge"=>0.0,
  "r5dn.8xlarge"=>0.0,
  "r5dn.12xlarge"=>0.0,
  "r5dn.16xlarge"=>0.0,
  "r5dn.24xlarge"=>0.0,
  "r5n.large"=>0.0,
  "r5n.xlarge"=>0.0,
  "r5n.2xlarge"=>0.0,
  "r5n.4xlarge"=>0.0,
  "r5n.8xlarge"=>0.0,
  "r5n.12xlarge"=>0.0,
  "r5n.16xlarge"=>0.0,
  "r5n.24xlarge"=>0.0,
  "r6g.medium"=>0.0,
  "r6g.large"=>0.0,
  "r6g.xlarge"=>0.0,
  "r6g.2xlarge"=>0.0,
  "r6g.4xlarge"=>0.0,
  "r6g.8xlarge"=>0.0,
  "r6g.12xlarge"=>0.0,
  "r6g.metal"=>0.0,
  "r6g.16xlarge"=>0.0,
  "x1.16xlarge"=>0.0,
  "x1.32xlarge"=>0.0,
  "x1e.xlarge"=>0.0,
  "x1e.2xlarge"=>0.0,
  "x1e.4xlarge"=>0.0,
  "x1e.8xlarge"=>0.0,
  "x1e.16xlarge"=>0.0,
  "x1e.32xlarge"=>0.0,
  "d2.xlarge"=>0.0,
  "d2.2xlarge"=>0.0,
  "d2.4xlarge"=>0.0,
  "d2.8xlarge"=>0.0,
  "d3.xlarge"=>0.0,
  "d3.2xlarge"=>0.0,
  "d3.4xlarge"=>0.0,
  "d3.8xlarge"=>0.0,
  "i2.xlarge"=>0.0,
  "i2.2xlarge"=>0.0,
  "i2.4xlarge"=>0.0,
  "i2.8xlarge"=>0.0,
  "i3.large"=>0.0,
  "i3.xlarge"=>0.0,
  "i3.2xlarge"=>0.0,
  "i3.4xlarge"=>0.0,
  "i3.8xlarge"=>0.0,
  "i3.16xlarge"=>0.0,
  "i3.metal"=>0.0,
  "i3en.large"=>0.0,
  "i3en.xlarge"=>0.0,
  "i3en.2xlarge"=>0.0,
  "i3en.3xlarge"=>0.0,
  "i3en.6xlarge"=>0.0,
  "i3en.12xlarge"=>0.0,
  "i3en.24xlarge"=>0.0
  }.freeze

  FILTER_SERVICE_TYPES_MAP = {
    'EC2' => 'Services::Compute::Server::AWS',
    'Volume' => 'Services::Compute::Server::Volume::AWS',
    'RDS' => 'Services::Database::Rds::AWS',
    'Security Groups' => 'Services::Network::SecurityGroup::AWS',
    'S3' => 'Storages::AWS',
    'AMI' => 'MachineImage',
    'Load Balancer' => 'Services::Network::LoadBalancer::AWS',
    'Auto Scaling' => 'Services::Network::AutoScaling::AWS',
    'Launch Configuration' => 'Services::Network::AutoScalingConfiguration::AWS',
    'VPC' => 'Vpcs::AWS',
    'Internet Gateway' => 'InternetGateways::AWS',
    'IAM' => 'IamUser',
    'Network Interface' => 'Services::Network::NetworkInterface::AWS',
    'Key Pair' => 'Resources::KeyPair',
    'IAM Certificate' => 'IamCertificate',
    'AWS Organisation' => 'AWSOrganisation',
    'Key Management' => 'EncryptionKey',
    'CloudWatch Logs' => 'CloudWatch',
    'AWS CloudTrail' => 'AWSTrail',
    'AWS Config' => 'AWSConfig',
    'IAM Group' => 'IamGroup',
    'IAM Role' => 'AWSIamRole',
    'AWS Account' => 'AWSAccount'
  }.freeze

  PROVIDER_MAPPER = {
    'AWS' => 'AWS',
    'Azure' => 'Azure',
    'GCP' => 'GCP',
    'VmWare' => 'VmWare'
  }
  
  VMWARE_DATA_REPROCESS_DAY = 10

  AWS_SERVICES = ['AWS AppSync','AWS Backup','AWS Budgets','AWS Certificate Manager','AWS Cloud Map','AWS CloudShell','AWS CloudTrail','AWS CodeArtifact','AWS CodeCommit','AWS CodePipeline','AWS Config','AWS Cost Explorer','AWS Data Transfer','AWS Directory Service','AWS Elemental MediaConnect','AWS Elemental MediaLive','AWS Elemental MediaPackage','AWS Elemental MediaStore','AWS Glue','AWS IoT','AWS IoT Device Management','AWS Key Management Service','AWS Lambda','AWS Premium Support','AWS Secrets Manager','AWS Security Hub','AWS Service Catalog','AWS Step Functions','AWS Support (Business)','AWS Support (Developer)','AWS Systems Manager','AWS Transfer Family','AWS WAF','AWS X-Ray','Amazon API Gateway','Amazon AppStream','Amazon Athena','Amazon CloudFront','Amazon Cognito','Amazon DocumentDB (with MongoDB compatibility)','Amazon DynamoDB','Amazon EC2 Container Registry (ECR)','Amazon EC2 Container Service','Amazon ElastiCache','Amazon Elastic Compute Cloud','Amazon Elastic Container Registry Public','Amazon Elastic Container Service','Amazon Elastic Container Service for Kubernetes','Amazon Elastic File System','Amazon Elastic MapReduce','Amazon Elasticsearch Service','Amazon FSx','Amazon GuardDuty','Amazon Inspector','Amazon Kendra','Amazon Kinesis','Amazon Kinesis Firehose','Amazon Lightsail','Amazon MQ','Amazon Macie','Amazon Managed Streaming for Apache Kafka','Amazon Polly','Amazon QuickSight','Amazon Redshift','Amazon Registrar','Amazon Rekognition','Amazon Relational Database Service','Amazon Route 53','Amazon Simple Email Service','Amazon Simple Notification Service','Amazon Simple Queue Service','Amazon Simple Storage Service','Amazon SimpleDB','Amazon Virtual Private Cloud','Amazon WorkSpaces','AmazonCloudWatch','AmazonWorkMail','Bastillion','Cloud Manager - Deploy & Manage NetApp Cloud Data Services','CloudWatch Events','CodeBuild','Databricks Unified Analytics Platform - Annual Commitment v2','EC2 Usage','Elastic Load Balancing','HashiCorp Vault OSS','Netgate pfSense Firewall/VPN/Router','Netgate pfSense Plus Firewall/VPN/Router','Oracle Enterprise Linux 7.6  supported by Navisite','Savings Plans for AWS Compute usage','Ubuntu VNC Desktop','AWS DataSync','AWS Device Farm','AWS Global Accelerator','Amazon Neptune','Amazon SageMaker','Amazon Simple Workflow Service','Amazon Sumerian','Amazon WorkDocs'].freeze

end
