module ServiceAdviser
  module Constants
    module AWS
      VOLUME_CLASS = 'Services::Compute::Server::Volume::AWS'.freeze
      SERVER_CLASS = 'Services::Compute::Server::AWS'.freeze
      RDS_CLASS = 'Services::Database::Rds::AWS'.freeze
      CONTAINER_CLASS = 'Services::Container::EKS::AWS'.freeze
      
      # this constant does not contain
      # AMI, IOPS, Snpashot service type
      SERVICE_TYPE_MAP  = {
        'volume' => VOLUME_CLASS,
        'idle_ec2' => SERVER_CLASS,
        'idle_load_balancer' => Service::LB_SERVICE_TYPES,
        'idle_rds' => RDS_CLASS,
        'idle_volume' => VOLUME_CLASS,
        'idle_stopped_ec2' => SERVER_CLASS,
        'idle_stopped_rds' => RDS_CLASS,
        'instances_sizing' => SERVER_CLASS,
        'rds_instances_sizing' => RDS_CLASS,
        'load_balancer' => Service::LB_SERVICE_TYPES,
        'ec2_right_sizings' => SERVER_CLASS,
        'rds_right_sizings' => RDS_CLASS,
        'unhealthy_eks' => CONTAINER_CLASS,
        'unused_eks' => CONTAINER_CLASS
      }.freeze
      
      SERVICE_NOT_APPLICABLE_FOR_TAG_SEARCH =
        [
          'Services::Network::InternetGateway::AWS',
          'Services::Network::NetworkInterface::AWS',
          'Services::Network::SecurityGroup::AWS',
          'Services::Network::Subnet::AWS',
          'Services::Vpc'
        ].freeze
      
      # Specific for snapshot
      SNAPSHOT_CATEGORY_MAP = {
        'volume_snapshot' => 'volume',
        'rds_snapshot' => 'rds'
      }.freeze

      # Specific for IOPS volume and RDS
      PROVISIONED_IOPS_CATEGORY_MAP = {
        'unused_provisioned_iops_rds' => RDS_CLASS,
        'unused_provisioned_iops_volumes' => VOLUME_CLASS
      }.freeze

      UNUSED_UNOPTIMIZED_MAP = {
        'volume' => VOLUME_CLASS,
        'idle_ec2' => SERVER_CLASS,
        'idle_load_balancer' => 'Service',
        'idle_rds' => RDS_CLASS,
        'idle_volume' => VOLUME_CLASS,
        'idle_stopped_ec2' => SERVER_CLASS,
        'idle_stopped_rds' => RDS_CLASS,
        'instances_sizing' => SERVER_CLASS,
        'rds_instances_sizing' => RDS_CLASS,
        'load_balancer' => 'Service',
        'rightsized_ec2' => SERVER_CLASS,
        'rightsized_rds' => RDS_CLASS,
        'rightsized_s3' => 'Storage',
        'unhealthy_eks' => CONTAINER_CLASS,
        'unused_eks' => CONTAINER_CLASS,
        'rds_snapshot' => 'Snapshot',
        'volume_snapshot'=> 'Snapshot',
        'launch_config' => 'Service',
        'amis' => "MachineImage",
        'elastic_ip'=> 'Service',
        'unused_provisioned_iops_rds' => 'Services::Database::Rds::AWS',
        'unused_provisioned_iops_volumes' => 'Services::Compute::Server::Volume::AWS'
        }.freeze
    end
  end
end