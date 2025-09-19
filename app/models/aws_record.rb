class AWSRecord < ApplicationRecord
  include Behaviors::Costable::Amazon

  VPC = "VPC"
  SECURITY_GROUP = "SecurityGroup"
  SUBNET = "Subnet"
  SUBNET_GROUP = "RDS::SubnetGroup"
  ROUTE_TABLE = "RouteTable"
  LOAD_BALANCER = "ELB::LoadBalancer"
  AUTO_SCALLING_GROUP = "AutoScaling::Group"
  AUTO_SCALLING_CONFIGURATION = "AutoScaling::Configuration"
  INTERNET_GATEWAY = "InternetGateway"
  SERVER = "Server"
  RDS = "RDS::Server"
  VOLUME = "Volume"
  ELASTIC_IP = "Address"
  NACL = "NetworkAcl"
  VOLUME_SNAPSHOT = "Snapshot"
  RDS_SNAPSHOT = "RDS::Snapshot"
  ENI = "NetworkInterface"
  APPLICATION_LOADBALANCER = "Application::LoadBalancer"
  NETWORK_LOADBALANCER = "Network::LoadBalancer"
  EKS = "EKS"

  SERVICE_TYPES = ["AWSRecords::Network::Vpc::AWS", "AWSRecords::Network::SecurityGroup::AWS", "AWSRecords::Network::Subnet::AWS", "AWSRecords::Network::SubnetGroup::AWS","AWSRecords::Network::RouteTable::AWS", "AWSRecords::Network::LoadBalancer::AWS", "AWSRecords::Network::AutoScaling::AWS", "AWSRecords::Network::AutoScalingConfiguration::AWS", "AWSRecords::Network::InternetGateway::AWS", "AWSRecords::Compute::Server::AWS","AWSRecords::Database::Rds::AWS", "AWSRecords::Compute::Server::Volume::AWS", "AWSRecords::Network::ElasticIP::AWS",  "AWSRecords::Network::Nacl::AWS", "AWSRecords::Network::NetworkInterface::AWS", "AWSRecords::Network::ApplicationLoadBalancer::AWS", "AWSRecords::Network::NetworkLoadBalancer::AWS", "AWSRecords::Container::EKS::AWS"]

  SERVICE_TYPES_HASH = SERVICE_TYPES.inject({}) {|h,i| h[i.split('::').reverse[1].downcase] = i; h}

  NON_CONNECTED_SERVICE_TYPES = [VOLUME, VOLUME_SNAPSHOT, RDS_SNAPSHOT, ELASTIC_IP, AUTO_SCALLING_CONFIGURATION, ENI]

  SERVICES_MAP = [ SECURITY_GROUP, SUBNET, ROUTE_TABLE, SERVER, INTERNET_GATEWAY, VPC, SUBNET_GROUP, RDS, VOLUME, LOAD_BALANCER, AUTO_SCALLING_GROUP, AUTO_SCALLING_CONFIGURATION, NACL, VOLUME_SNAPSHOT, RDS_SNAPSHOT, ENI, ELASTIC_IP, APPLICATION_LOADBALANCER, NETWORK_LOADBALANCER ]

  SYNC_SERVICES_MAP = [VPC, SECURITY_GROUP, SUBNET, SUBNET_GROUP, INTERNET_GATEWAY,NACL, ROUTE_TABLE, SERVER, RDS, VOLUME, LOAD_BALANCER, AUTO_SCALLING_GROUP, AUTO_SCALLING_CONFIGURATION, VOLUME_SNAPSHOT, RDS_SNAPSHOT, ENI, ELASTIC_IP, APPLICATION_LOADBALANCER, NETWORK_LOADBALANCER, EKS ]

  SERVICES_FOR_SYNC_ADDITIONAL_DATA = ["AWSRecords::Database::Rds::AWS", "AWSRecords::Network::AutoScaling::AWS", "AWSRecords::Network::LoadBalancer::AWS", "AWSRecords::Network::Vpc::AWS"]

  SERVICES_ORDER = SERVICES_MAP
  # self.inheritance_column = :_type_disabled

  store_accessor :data
  attr_accessor :synchronization_id
  belongs_to :adapter
  belongs_to :account
  belongs_to :region

  #service type corresponds to the suffix of the class names that fog returns
  scope :vpcs, ->{ where(type: AWSRecords::Network::Vpc::AWS.to_s) }
  scope :security_groups, ->{ where(type: AWSRecords::Network::SecurityGroup::AWS.to_s) }
  scope :subnets, ->{ where(type: AWSRecords::Network::Subnet::AWS.to_s) }
  scope :subnet_groups, ->{ where(type: AWSRecords::Network::SubnetGroup::AWS.to_s) }
  scope :route_tables, ->{ where(type: AWSRecords::Network::RouteTable::AWS.to_s) }
  scope :elastic_ips, ->{ where(type: AWSRecords::Network::ElasticIP::AWS.to_s) }
  scope :load_balancers, ->{ where(type: AWSRecords::Network::LoadBalancer::AWS.to_s) }
  scope :auto_scallings, ->{ where(type: AWSRecords::Network::AutoScaling::AWS.to_s) }
  scope :auto_scalling_configurations, ->{ where(type: AWSRecords::Network::AutoScalingConfiguration::AWS.to_s) }
  scope :internet_gateways, ->{ where(type: AWSRecords::Network::InternetGateway::AWS.to_s) }
  scope :servers, ->{ where(type: AWSRecords::Compute::Server::AWS.to_s) }
  scope :volumes, ->{ where(type: AWSRecords::Compute::Server::Volume::AWS.to_s) }
  scope :rds, ->{ where(type: AWSRecords::Database::Rds::AWS.to_s) }
  scope :nacls, ->{ where(type: AWSRecords::Network::Nacl::AWS.to_s) }
  scope :volume_snapshots, ->{ where(type: AWSRecords::Snapshots::Volume::AWS.to_s) }
  scope :rds_snapshots, ->{ where(type: AWSRecords::Snapshots::Rds::AWS.to_s) }
  scope :network_interfaces, ->{ where(type: AWSRecords::Network::NetworkInterface::AWS.to_s) }
  scope :by_vpc, ->(vpc_id){ where(provider_vpc_id: vpc_id) }
  scope :non_connected_service_types, ->{ where(service_type: NON_CONNECTED_SERVICE_TYPES)}
  scope :find_reserved_servers_by, ->(adapter, region, account) { where(adapter: adapter, region: region, account: account)}

  def initialize(attributes={})
    super(attributes)
    self.set_provider_id
  end

  def get_possible_ejectable_services
    []
  end

  def self.get_service_type(aws_type)
    case(aws_type)
    when VPC
      AWSRecords::Network::Vpc::AWS
    when SECURITY_GROUP
      AWSRecords::Network::SecurityGroup::AWS
    when SUBNET
      AWSRecords::Network::Subnet::AWS
    when SUBNET_GROUP
      AWSRecords::Network::SubnetGroup::AWS
    when ROUTE_TABLE
      AWSRecords::Network::RouteTable::AWS
    when LOAD_BALANCER
      AWSRecords::Network::LoadBalancer::AWS
    when AUTO_SCALLING_GROUP
      AWSRecords::Network::AutoScaling::AWS
    when AUTO_SCALLING_CONFIGURATION
      AWSRecords::Network::AutoScalingConfiguration::AWS
    when INTERNET_GATEWAY
      AWSRecords::Network::InternetGateway::AWS
    when SERVER
      AWSRecords::Compute::Server::AWS
    when RDS
      AWSRecords::Database::Rds::AWS
    when VOLUME
      AWSRecords::Compute::Server::Volume::AWS
    when ELASTIC_IP
      AWSRecords::Network::ElasticIP::AWS
    when VOLUME_SNAPSHOT
      AWSRecords::Snapshots::Volume::AWS
    when RDS_SNAPSHOT
      AWSRecords::Snapshots::Rds::AWS
    when NACL
      AWSRecords::Network::Nacl::AWS
    when ENI
      AWSRecords::Network::NetworkInterface::AWS
    when NETWORK_LOADBALANCER
      AWSRecords::Network::NetworkLoadBalancer::AWS
    when APPLICATION_LOADBALANCER
      AWSRecords::Network::ApplicationLoadBalancer::AWS
    when EKS
      AWSRecords::Container::EKS::AWS
    else
      raise "-=-=--=-=-=-=-=-=Unidentified Service-=-=--=-=-=-=-=-="
    end
  end

  def set_default_addtional_data
    {}
  end
  #Sync data not yet stable while in creating state (some properties are left blank)
  #Most of the services are created instantly and hence by default they have creating false
  #Those services that take time to create need to override this method and inturn have their state checked
  def creating?
    false
  end

  def self.set_provider_vpc_id(vpc_mapper, attributes)
    attributes
  end

  def set_provider_id

  end

  def self.is_ec2_classic_service?(attributes)
    false
  end

  def self.sort(services)
    services.to_a.sort!{ |service_x, service_y|
      service_x.draw_order <=> service_y.draw_order
    }
  end

  def draw_order
    SERVICES_ORDER.index(self.service_type)||SERVICES_ORDER.length
  end

  def reusable?
    self.class::REUSABLE
  end

  def used_in_environment?
    account.service_used_in_environment?(self)
  end

  def snapshot_used_in_environment?
    snapshot = true
    if account.snapshots
      snapshot = account.snapshots.where({
                                           provider_id: self.provider_id,
                                           adapter_id: self.adapter_id,
                                           region_id: self.region_id
      }).where.not(environment_id: nil)
    end
    snapshot
  end

  def is_healthy?
    true
  end

  def detached?
    false
  end

  def synchronize(auto_sync_on = true)
    return if self.provider_id.blank?
    filters = {adapter_id: self.adapter_id, region_id: self.region_id, account_id: self.account_id, provider_id: self.provider_id}
    attributes = self.class::SERVICE_CLASS.constantize.get_data_store_attributes(self)
    if auto_sync_on
      #update services from cloudstreet
      state = attributes[:state]
      self.class::SERVICE_CLASS.constantize.where(filters).each do |service|
        if service.state.eql?("template")
          attributes.merge!(state: "template")
        elsif service.state.eql?("environment")
          attributes.merge!(state: "environment")
        else
          attributes.merge!(state: state)
        end
        service.update_up_and_start_time if service.try :is_server?
        service.state = "template" if service.state.eql?("template")
        service.state = "environment" if service.state.eql?("environment")
        service.attributes = service.attributes.merge(attributes)
        service.try(:provider_type=, "Providers::AWS")
        service.cost_by_hour = self.cost_by_hour
        service.error_message = nil
        service.data_will_change!
        service.created_by = service.environment.created_by if service.created_by.blank? && service.environment.present?
        if service.valid?
          service.save!
          service.check_and_mark_unused if ["Services::Network::LoadBalancer::AWS", "Services::Network::ApplicationLoadBalancer::AWS", "Services::Network::NetworkLoadBalancer::AWS"].include?(service.class.name)
          #service.check_and_mark_unused if service.class.name == "Services::Network::LoadBalancer::AWS"
        else
          CloudStreet.log "Service already exists"
          CloudStreet.log "Error while saving the snapshot of #{service.id} =-=-=-=-------#{service.errors.messages}"
          if service.kind_of?(Service)
            CloudStreet.log "Dulication records are --for service------ #{self.class::SERVICE_CLASS.constantize.where(filters.except(:provider_id)).pluck(:id, :name, :provider_id, :created_at, :state)}"  rescue nil
          else
            CloudStreet.log "Dulication records are --for snapshot------ #{self.class::SERVICE_CLASS.constantize.where(filters.except(:provider_id)).pluck(:id, :name, :provider_id, :created_at, :state, :archived)}"  rescue nil
          end
        end
      end
    end
    if self.detached? && !self.class::SERVICE_CLASS.constantize.where(filters).exists?
      service = self.class::SERVICE_CLASS.constantize.new(attributes.merge(filters))
      service.try(:provider_type=, "Providers::AWS")
      if service.valid?
        service.cost_by_hour = self.cost_by_hour
        service.save!
      else
        CloudStreet.log "Service new"
        CloudStreet.log "Error while saving the snapshot of #{service.id} =-=-=-=-------#{service.errors.messages}"
        if service.kind_of?(Service)
          CloudStreet.log "Dulication records are --for service------ #{self.class::SERVICE_CLASS.constantize.where(filters.except(:provider_id)).pluck(:id, :name, :provider_id, :created_at, :state)}"  rescue nil
        else
          CloudStreet.log "Dulication records are --for snapshot------ #{self.class::SERVICE_CLASS.constantize.where(filters.except(:provider_id)).pluck(:id, :name, :provider_id, :created_at, :state, :archived)}"  rescue nil
        end
      end
    end
  end

  # override if required
  def process_service_data(extra_options={})
    {}
  end

  def synced_service?
    account.services.where(
      adapter: self.adapter,
      region: self.region,
      type: self.class::SERVICE_CLASS,
      provider_id: self.provider_id
    ).synced_services.first.present?
  end

  def self.not_used_by_any_environment
    select{|service| !service.used_in_environment? }
  end

  module CommonAttributeMapper
    def update_base_table(remote_service)
      filters = {
        provider_id: remote_service.provider_id,
        adapter_id: remote_service.adapter_id,
        account_id: remote_service.account_id,
        region_id: remote_service.region_id,
        vpc_id: remote_service.vpc_id
      }
      service = where(filters).first || self.new
      service.set_attributes = filters.merge({
                                               provider_data: remote_service.provider_data
      }).merge(format_attributes_by_raw_data(
                 OpenStruct.new(remote_service.provider_data)
      ))
      yield(service, filters) if block_given?
      service.save! if service.changed?
      service
    end

    def get_data_store_attributes(ds_service)
      service = OpenStruct.new(ds_service.data)
      format_attributes_by_raw_data(service).merge({
                                                     adapter_id: ds_service.adapter_id,
                                                     account_id: ds_service.account_id,
                                                     region_id: ds_service.region_id,
                                                     provider_id: ds_service.provider_id,
                                                     provider_data: ds_service.data
      })
    end
  end
end
