class CSService < ApplicationRecord
  include Behaviors::BulkInsert

  attr_accessor :sync_status, :user, :is_unallocated, :tags

  belongs_to :adapter
  belongs_to :account
  belongs_to :region
  belongs_to :subscription
  
  has_one    :environment_CS_service
  has_one    :environment, through: :environment_CS_service
  has_one    :template_CS_service
  has_one    :template, through: :template_CS_service
  has_one :azure_cost_summary, class_name: 'Azure::CostSummary'

  has_many :associated_services
  has_many :CS_service_tags
  has_many :tag_key_values, through: :CS_service_tags

  has_many :associated_services
  has_many :associated_CS_services, :foreign_key  => "associated_CS_service_id", :class_name => "AssociatedService"
  has_many :CS_child_services, through: :associated_CS_services, :source => :CS_service
  has_many :CS_parent_services, through: :associated_services, :source => :CS_parent_service

  VNET = "Azure::Network::Vnet"
  SUBNET = "Azure::Network::Subnet"
  ROUTE_TABLE = "Azure::Network::RouteTable"
  NETWORK_SECURITY_GROUP = "Azure::Network::SecurityGroup"
  NETWORK_INTERFACE = "Azure::Network::NetworkInterface"
  PUBLIC_IP_ADDRESS = "Azure::Network::PublicIPAddress"
  LOAD_BALANCER = "Azure::Network::LoadBalancer"

  RESOURCE_GROUP = "Azure::Resource::ResourceGroup"
  
  VIRTUAL_MACHINE = "Azure::Compute::VirtualMachine"
  DISK =  "Azure::Compute::VirtualMachine::Disk"
  AVAILABILITY_SET = "Azure::Compute::AvailabilitySet"
  DATABASE_SERVER = "Azure::Database::SQL::DBServer"
  DATABASE = "Azure::Database::SQL::DB"
  STORAGE_ACCOUNT = "Azure::Storage::StorageAccount"
  
  NETAPP_FILER_VOLUME = "FilerVolumes::CloudResources::NetApp"
  GENERIC_TYPE_MAPPER = {
    "subnet" => SUBNET,
    "routetable" => ROUTE_TABLE,
    "securitygroup" => NETWORK_SECURITY_GROUP,
    "virtualmachine" => VIRTUAL_MACHINE,
    "networkinterface" => NETWORK_INTERFACE,
    "loadbalancer" => LOAD_BALANCER,
    "disk" => DISK,
    "publicipaddress" => PUBLIC_IP_ADDRESS
  }

  RESOURCE_PROVIDER_AZURE_RECORD_MAPPER = {
    "Microsoft.Resource/resourceGroups" => RESOURCE_GROUP,
    "Microsoft.Network/virtualNetworks" => VNET,
    "Microsoft.Network/networkInterfaces" => NETWORK_INTERFACE,
    "Microsoft.Network/routeTables" => ROUTE_TABLE,
    "Microsoft.Network/publicIPAddresses" => PUBLIC_IP_ADDRESS,
    "Microsoft.Compute/virtualMachines" => VIRTUAL_MACHINE,
    "Microsoft.Network/loadBalancers" => LOAD_BALANCER,
    "Microsoft.Network/networkSecurityGroups" => NETWORK_SECURITY_GROUP,
    "Microsoft.Compute/availabilitySets" => AVAILABILITY_SET,
    "Microsoft.Storage/storageAccounts" => STORAGE_ACCOUNT,
    "Microsoft.Sql/servers" => DATABASE_SERVER,
    "Microsoft.Sql/servers/databases" => DATABASE,
    "Microsoft.Compute/disks" => DISK,
    "Microsoft.Network/subnet" => SUBNET,
  }

  AZURE_SERVICES_PROCESS_SEQUENCE = [VNET, AVAILABILITY_SET, STORAGE_ACCOUNT, PUBLIC_IP_ADDRESS, ROUTE_TABLE, NETWORK_SECURITY_GROUP, SUBNET, NETWORK_INTERFACE, LOAD_BALANCER, VIRTUAL_MACHINE, DISK, DATABASE_SERVER, DATABASE, "Azure::Compute::VirtualMachine::InstanceFiler"]

  CS_SUPPORTED_AZURE_SERVICES = %w(Microsoft.Network/virtualNetworks Microsoft.Network/networkInterfaces Microsoft.Network/routeTables Microsoft.Network/publicIPAddresses Microsoft.Compute/virtualMachines Microsoft.Network/loadBalancers Microsoft.Network/networkSecurityGroups Microsoft.Compute/availabilitySets Microsoft.Storage/storageAccounts Microsoft.Sql/servers Microsoft.Sql/servers/databases Microsoft.Compute/disks)

  # NETAPP_FILER_VOLUME = "FilerVolumes::CloudResources::NetApp"

  SERVICE_DELETING_STATES = [:terminating, :terminated, :deleting, :deleted , :removed_from_provider]

  COSTABLE_SERVICES = [VIRTUAL_MACHINE, DISK, PUBLIC_IP_ADDRESS, DATABASE]

  AZURE_TEMPLATABLE_SERVICES = [VNET, SUBNET, ROUTE_TABLE, NETWORK_SECURITY_GROUP, NETWORK_INTERFACE, PUBLIC_IP_ADDRESS, VIRTUAL_MACHINE, NETAPP_FILER_VOLUME, "Azure::Compute::VirtualMachine::InstanceFiler", DISK, STORAGE_ACCOUNT]

  has_one :azure_vnet, class_name: 'Azure::Network::Vnet'
  has_one :azure_subnet, class_name: 'Azure::Network::Subnet'
  has_one :azure_security_group, class_name: 'Azure::Network::SecurityGroup'
  has_one :azure_route_table, class_name: 'Azure::Network::RouteTable'
  has_one :azure_public_ip_address, class_name: 'Azure::Network::PublicIPAddress'
  has_one :azure_network_interface, class_name: 'Azure::Network::NetworkInterface'
  has_one :azure_load_balancer, class_name: 'Azure::Network::LoadBalancer'
  has_one :azure_storage_account, class_name: 'Azure::Storage::StorageAccount'
  has_one :azure_virtual_machine, class_name: 'Azure::Compute::VirtualMachine'
  has_one :azure_availability_set, class_name: 'Azure::Compute::AvailabilitySet'
  has_one :azure_disk, class_name: 'Azure::Compute::VirtualMachine::Disk'
  has_one :azure_resource_group, class_name: 'Azure::Resource::ResourceGroup'
  has_one :azure_sql_db_server, class_name: 'Azure::Database::SQL::DBServer'
  has_one :azure_sql_db, class_name: 'Azure::Database::SQL::DB'
  has_one :filer_volume

  has_many :service_tags

  scope :synced_CS_services, -> { 
    joins("LEFT JOIN environment_CS_services ON environment_CS_services.CS_service_id = CS_services.id").where(environment_CS_services: {environment_id: nil }).
    where.not({ CS_services: { state: (['template', 'pending' ] + SERVICE_DELETING_STATES) } })
  }

  def cost_summary
    # need to change this- may be using reflections
    self.azure_cost_summary
  end

  def is_costable?
    COSTABLE_SERVICES.include? self.service_type
  end
  
  scope :vnets, -> { where(service_type: VNET) }
  scope :subnets, -> { where(service_type: SUBNET) }
  scope :route_tables, -> { where(service_type: ROUTE_TABLE) }
  scope :security_groups, -> { where(service_type: NETWORK_SECURITY_GROUP) }
  scope :network_interfaces, -> { where(service_type: NETWORK_INTERFACE) }
  scope :public_ips, -> { where(service_type: PUBLIC_IP_ADDRESS) }
  scope :vms, -> { where(service_type: VIRTUAL_MACHINE) }
  scope :disks, -> { where(service_type: DISK) }
  scope :filer_volumes, -> { where(service_type: NETAPP_FILER_VOLUME) }

  def properties
    send(self.service_type.constantize.table_name.singularize).try(:properties) || {}
  end


  def get_extra_metadata
    case service_type
    when VNET
      security_groups = self.CS_child_services.security_groups.map(&:name)
      route_tables = self.CS_child_services.route_tables.map(&:name)
      return [{
        "name"  => "route_tables",
        "title" => "Route Table",
        "value" => route_tables
      },
      {
        "name"  => "security_groups",
        "title" => "Secrity Groups",
        "value" => security_groups
      }
    ]
    when VIRTUAL_MACHINE
      grouped_parent_services = associated_services.group_by(&:service_type)
      CS_nic_ids = grouped_parent_services[NETWORK_INTERFACE].map(&:associated_CS_service_id) rescue []
      public_ips = CS_nic_ids.present? ? CSService.includes(:azure_public_ip_address).joins(:associated_CS_services).public_ips.where(associated_services: {CS_service_id: CS_nic_ids}).map { |p_ip| {name: p_ip.name, ip_address: p_ip.azure_public_ip_address.ip_address, public_ipallocation_method: p_ip.azure_public_ip_address.public_ipallocation_method} } : []
      security_groups = CS_nic_ids.present? ? CSService.joins(:associated_CS_services).security_groups.where(associated_services: {CS_service_id: CS_nic_ids}).pluck(:name) : []
      return [{
        "name"  => "public_ips",
        "title" => "Public IPs",
        "value" => public_ips
      },
      {
        "name"  => "security_groups",
        "title" => "Secrity Groups",
        "value" => security_groups
      }
    ]
    when NETWORK_INTERFACE
      security_groups = CSService.joins(:associated_CS_services).security_groups.where(associated_services: {CS_service_id: self.id})
      security_groups = security_groups.present? ? security_groups.pluck(:name) : []
      public_ips = CSService.includes(:azure_public_ip_address).joins(:associated_CS_services).public_ips.where(associated_services: {CS_service_id: self.id})
      public_ips = public_ips.present? ? public_ips.map { |p_ip| {name: p_ip.name, ip_address: p_ip.azure_public_ip_address.ip_address, public_ipallocation_method: p_ip.azure_public_ip_address.public_ipallocation_method} } : []
      return [{
        "name"  => "public_ips",
        "title" => "Public IPs",
        "value" => public_ips
      },
      {
        "name"  => "security_groups",
        "title" => "Secrity Groups",
        "value" => security_groups
      }]
    when NETAPP_FILER_VOLUME
      volume_type = self.filer_volume.actual_protocol
      return [{
        "name"  => "volume_type",
        "title" => "Filer Volume Type",
        "value" => volume_type
      }]
    when SUBNET
      route_tables = self.CS_child_services.route_tables.map(&:name)
      security_groups = self.CS_parent_services.security_groups.pluck(:name)
      return [{
          "name"  => "route_tables",
          "title" => "Route Table",
          "value" => route_tables
        },
        {
          "name"  => "security_groups",
          "title" => "Secrity Group",
          "value" => security_groups
        }
      ]
    else
      return {}
    end
  end

  def cost_summary
    # need to change this- may be using reflections
    self.azure_cost_summary
  end

  def is_costable?
    COSTABLE_SERVICES.include? self.service_type
  end
  
  class << self
    def create_or_update_all_from_remote(parser)
      parent = create_or_update_from_remote(parser)
      services = [parent]
      parser.associated_service_parsers.inject(services) do|list, service_parser|
        associated_service = create_or_update_from_remote(service_parser)
        AssociatedService.find_or_create_by({
          "associated_CS_service_id" => parent.CS_service_id,
          "CS_service_id" => associated_service.CS_service_id
        })do|association|
          association.service_type = parent.class.name
          association.name = parent.name
        end
        list.push(associated_service)
      end
    end

    def create_or_update_from_remote(parser)
      klass = parser.class.to_s.split("Parsers::").last.constantize
      attributes = parser.creation_attributes
      service = klass.find_or_initialize_by(adapter_id: attributes["adapter_id"], subscription_id: attributes["subscription_id"],  provider_id: attributes["provider_id"])
      attributes[:CS_service_attributes].merge!(id: service.CS_service_id) if service.CS_service_id.present?
      service.tags = attributes.delete("tags")
      service.assign_attributes(attributes)
      service.save!
      service
    end

    def synchronize_all(remote_service_list, common_attributes)
      remote_service_list.compact!
      results = (remote_service_list.collect do|remote_service_hash|
        remote_service_hash.merge!(common_attributes).stringify_keys!
        service_type = remote_service_hash['type']
        parser_klass = "Parsers::#{RESOURCE_PROVIDER_AZURE_RECORD_MAPPER[service_type]}"
        next if parser_klass.eql?("Parsers::Azure::Storage")
        parser = parser_klass.constantize.new(remote_service_hash)
        if parser.has_associated_serices?
          create_or_update_all_from_remote(parser)
        else
          create_or_update_from_remote(parser)
        end
      end).compact.flatten
      results
    end

    def get_all_available_reusable_services_for_azure(vnet)
      # move this logic to azure specific code
      security_groups = Azure::Network::SecurityGroup.where(adapter_id: vnet.adapter_id, subscription_id: vnet.subscription_id)
      route_tables = Azure::Network::RouteTable.where(adapter_id: vnet.adapter_id, subscription_id: vnet.subscription_id)
      nics = Azure::Network::NetworkInterface.where(adapter_id: vnet.adapter_id, subscription_id: vnet.subscription_id)
      {security_groups: security_groups, route_tables: route_tables, nics: nics}
    end
    
    def fetch_vpc_associated_services(CS_service_vpc_id)
      CSService.joins("LEFT JOIN associated_services ON associated_services.CS_service_id = CS_services.id").where("associated_services.associated_CS_service_id = ? OR CS_services.id = ?", CS_service_vpc_id, CS_service_vpc_id).includes(:azure_cost_summary, :associated_services)  
    end
  end
end
