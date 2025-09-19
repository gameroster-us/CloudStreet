class Azure::Resource < ApplicationRecord
  self.table_name = 'azure_resources'

  attr_accessor :comment_count, :ignore_till, :actual_cost_meter_data
  belongs_to :adapter
  belongs_to :region
  belongs_to :resource_group, class_name: "Azure::ResourceGroup", foreign_key: :azure_resource_group_id
  has_and_belongs_to_many :child_resources, class_name: "Azure::Resource", join_table: "azure_resource_connections", foreign_key: "resource_id", association_foreign_key: "associated_resource_id"

  has_and_belongs_to_many :parent_resources, class_name: "Azure::Resource", join_table: "azure_resource_connections", foreign_key: "associated_resource_id", association_foreign_key: "resource_id"

  delegate :name, to: :resource_group, prefix: :resource_group
  delegate :name, to: :adapter, prefix: :adapter
  delegate :subscription_id, to: :adapter
  delegate :account_id, to: :adapter
  delegate :region_name, to: :region
  delegate :code, to: :region, prefix: :region

  RESOURCE_ACTIVE_STATUS  = [:creating, :created, :error, :reloading, :modifying, :deleting].freeze
  RESOURCE_PENDING_STATUS = [:pending, :template].freeze
  RESOURCE_DELETING_STATES = [:terminating, :terminated, :deleting, :deleted, :removed_from_provider].freeze
  EA_ADAPTER_ATHENA_CATEGORY_LIST = ["Azure Database for MariaDB", "Virtual Machines Licenses", "Virtual Machines", "Storage", "Load Balancer", "Virtual Network", "Azure Database for MySQL", "SQL Database", "Azure Database for PostgreSQL", "Advanced Data Security", "SQL Managed Instance", "SQL Data Warehouse", "Azure Synapse Analytics", "Advanced Threat Protection", "Azure Kubernetes Service", "Azure App Service"] + Azure::Resource::StorageAccount::STORAGE_TYPES
  USAGE_COST_KEY = 'usage_cost'.freeze

  scope :virtual_machines,    -> { where(type: "Azure::Resource::Compute::VirtualMachine") }
  scope :disks,               -> { where(type: "Azure::Resource::Compute::Disk") }
  scope :availability_sets,   -> { where(type: "Azure::Resource::Compute::AvailabilitySet") }
  scope :load_balancers,      -> { where(type: "Azure::Resource::Network::LoadBalancer") }
  scope :network_interfaces,  -> { where(type: "Azure::Resource::Network::NetworkInterface") }
  scope :public_ip_addresses, -> { where(type: "Azure::Resource::Network::PublicIPAddress") }
  scope :route_table,         -> { where(type: "Azure::Resource::Network::RouteTable") }
  scope :security_group,      -> { where(type: "Azure::Resource::Network::SecurityGroup") }
  scope :subnets,             -> { where(type: "Azure::Resource::Network::Subnet") }
  scope :vnets,               -> { where(type: "Azure::Resource::Network::Vnet") }
  scope :sqldb,               -> { where(type: "Azure::Resource::Database::SQL::DB") }
  scope :mariadb,             -> { where(type: "Azure::Resource::Database::MariaDB::Server") }
  scope :postgresdb,          -> { where(type: "Azure::Resource::Database::PostgreSQL::Server") }
  scope :mysqldb,             -> { where(type: "Azure::Resource::Database::MySQL::Server") }
  scope :elastic_pools,       -> { where(type: "Azure::Resource::Database::SQL::ElasticPool") }

  scope :find_with_tags,      (lambda do |s_tags, tag_operator, account=nil|
    general_setting = GeneralSetting.find_by(account_id: account || CurrentAccount.account_id)
    tag_operator ||= 'OR'
    general_setting&.is_tag_case_insensitive ? find_with_case_insensitive_tags(s_tags, tag_operator) : find_with_case_sensitive_tags(s_tags, tag_operator)
  end)

  scope :active, -> { where(state: RESOURCE_ACTIVE_STATUS) }

  scope :exclude_task_resources, -> { where.not(state: RESOURCE_DELETING_STATES + %w[pending error archived template]) }
  scope :exclude_aks_resource_group_services, -> {joins(:resource_group).where("azure_resource_groups.properties->>'type' !='Microsoft.ContainerService' or azure_resource_groups.properties->'type' is null")}
  scope :exclude_databricks_resource_group_services, -> {joins(:resource_group).where("azure_resource_groups.properties->>'type' !='Microsoft.Databricks' or azure_resource_groups.properties->'type' is null")}
  scope :exclude_data_warehouse_resources, -> { where.not("provider_data->'sku'->>'tier'=?", 'DataWarehouse') }
  scope :exclude_elastic_pool_dbs, -> { where("provider_data->>'elastic_pool_id' is NULL") }

  scope :ignored_resources, -> { where.not("ignored_from && ARRAY['un-ignored']::varchar[]") }
  scope :un_ignored_resources, -> { where("ignored_from && ARRAY['un-ignored']::varchar[]") }
  scope :stopped_deallocated_vm, -> { where("data->>'vm_status'='stopped (deallocated)'") }
  # scope :not_ignored, -> { where.not("ignored_from && ARRAY['all']::varchar[]") }
  scope :not_ignored_from, (lambda do |ignored_from_list = []|
    category_str = build_ignored_categories_str(ignored_from_list)
    where.not("ignored_from && #{category_str}::varchar[]")
  end)

  scope :ignored_from_categories, (lambda do |ignored_from_list = []|
    category_str = build_ignored_categories_str(ignored_from_list)
    where("ignored_from && #{category_str}::varchar[]")
  end)

  scope :filter_resource_group, -> (resource_group_ids) { where(azure_resource_group_id: resource_group_ids) if resource_group_ids.present? }
  scope :include_active_sas_disk_status, -> { where("provider_data->>'disk_state'='ActiveSAS'") }
  scope :reserved_vms, -> { where('array_to_json(meter_data)::jsonb @> ? OR array_to_json(meter_data)::jsonb @> ?', [{'meter_sub_category' => 'Reservation-Base VM'}].to_json, [{'service_tier' => 'VM RI'}].to_json) }
  scope :non_reserved_vms, -> { where.not('array_to_json(meter_data)::jsonb @> ? OR array_to_json(meter_data)::jsonb @> ?', [{'meter_sub_category' => 'Reservation-Base VM'}].to_json, [{'service_tier' => 'VM RI'}].to_json) }
  scope :idle_resources, -> { where(idle_instance: true) }

  RESOURCE_CLASS_MAPPING = {
    "Azure::Resource::Network::Vnet" => 'Virtual Network',
    "Azure::Resource::Network::RouteTable" => 'Route Table',
    "Azure::Resource::Network::SecurityGroup" => 'Security Group',
    "Azure::Resource::Network::PublicIPAddress" => 'PublicIp Address',
    "Azure::Resource::Network::NetworkInterface" => 'Network Interface',
    "Azure::Resource::Network::LoadBalancer" => 'LoadBalancer',
    "Azure::Resource::Compute::AvailabilitySet" => 'AvailabilitySet',
    "Azure::Resource::Compute::Disk" => 'Disk',
    "Azure::Resource::Compute::VirtualMachine" => 'Virtual Machine',
    "Azure::Resource::Compute::Snapshot" => 'Snapshot',
    "Azure::Resource::Database::MariaDB::Server" => 'Maria DB Server',
    "Azure::Resource::Database::MySQL::Server" => 'MySQL Server',
    "Azure::Resource::Database::PostgreSQL::Server" => 'PostgreSQL Server',
    "Azure::Resource::Database::SQL::Server" => 'SQL Server',
    "Azure::Resource::StorageAccount" => 'Storage Account',
    'Azure::Resource::Container::AKS' => 'Container AKS',
    'Azure::Resource::Web::AppService' => 'App Service',
    'Azure::Resource::Web::AppServicePlan' => 'AppService Plan'
  }


  VNET                      = "Azure::Resource::Network::Vnet".freeze
  SUBNET                    = "Azure::Resource::Network::Subnet".freeze
  ROUTE_TABLE               = "Azure::Resource::Network::RouteTable".freeze
  SECURITY_GROUP            = "Azure::Resource::Network::SecurityGroup".freeze
  NETWORK_INTERFACE         = "Azure::Resource::Network::NetworkInterface".freeze
  PUBLIC_IP_ADDRESS         = "Azure::Resource::Network::PublicIPAddress".freeze
  LOAD_BALANCER             = "Azure::Resource::Network::LoadBalancer".freeze

  RESOURCE_GROUP            = "Azure::ResourceGroup".freeze

  VIRTUAL_MACHINE           = "Azure::Resource::Compute::VirtualMachine".freeze
  DISK                      = "Azure::Resource::Compute::Disk".freeze
  AVAILABILITY_SET          = "Azure::Resource::Compute::AvailabilitySet".freeze
  SNAPSHOT                  = "Azure::Resource::Compute::Snapshot".freeze

  SQL_SERVER                = "Azure::Resource::Database::SQL::Server".freeze
  SQL_DATABASE              = "Azure::Resource::Database::SQL::DB".freeze
  POSTGRE_SQL_SERVER        = "Azure::Resource::Database::PostgreSQL::Server".freeze
  MY_SQL_SERVER             = "Azure::Resource::Database::MySQL::Server".freeze
  MARIA_DB_SERVER           = "Azure::Resource::Database::MariaDB::Server".freeze

  STORAGE_ACCOUNT           = "Azure::Resource::StorageAccount".freeze

  AKS_CONTAINER             = 'Azure::Resource::Container::AKS'.freeze

  SQL_ELASTIC_POOL          = 'Azure::Resource::Database::SQL::ElasticPool'

  APP_SERVICE               = 'Azure::Resource::Web::AppService'.freeze

  APP_SERVICE_PLAN          = 'Azure::Resource::Web::AppServicePlan'.freeze

  COSTABLE_SERVICES         = [VIRTUAL_MACHINE, DISK, PUBLIC_IP_ADDRESS, LOAD_BALANCER, SQL_SERVER, SQL_DATABASE,
                               POSTGRE_SQL_SERVER, MY_SQL_SERVER, MARIA_DB_SERVER, STORAGE_ACCOUNT, SNAPSHOT, AKS_CONTAINER,
                               APP_SERVICE, APP_SERVICE_PLAN, SQL_ELASTIC_POOL].freeze

  def find_or_initialize_connetion(resource_id, associated_resource_id)
    Azure::ResourceConnection.find_or_initialize_by(resource_id: resource_id, associated_resource_id: associated_resource_id)
  end

  def build_azure_resource_url
    "/subscriptions/#{subscription_id}/resourceGroups/#{resource_group_name}/providers/#{self.class::AZURE_RESOURCE_TYPE}/#{name}"
  end

  def azure_resource_url
    provider_data["id"]
  end

  def set_meter_data(usage_costs=nil)
    return unless self.class::COSTABLE_SERVICES.include?(self.class.name)
    # usage_costs ||= (Rails.cache.read("usage_cost_#{adapter.id}") || [])
    # usage_costs ||= (adapter.subscription.usage_cost.aggregate_usage_cost || [])
    if self.class.name.eql?("Azure::Resource::StorageAccount") && !(adapter.azure_cloud.eql?("AzureChinaCloud") || adapter.csp_adapter? || adapter.ea_adapter?)
      sa_temp_usage = Azure::SyncTempUsageCost.where(resource_uri: azure_resource_url.try(:downcase), resource_type: 'Storage')
      self.meter_data = sa_temp_usage.pluck(:usage_costs)
      self.data.merge!('currency' => sa_temp_usage.pluck(:currency).first)
    elsif adapter.azure_cloud.eql?("AzureChinaCloud") || adapter.csp_adapter? || adapter.ea_adapter? 
      # We are saving 30 days data for CSP, CHINA AND EA Adapter later we will select unit based on condition.
      sa_temp_usage = Azure::SyncTempUsageCost.where(resource_uri: azure_resource_url.try(:downcase))

      self.meter_data = sa_temp_usage.pluck(:usage_costs)
      self.data.merge!('currency' => sa_temp_usage.pluck(:currency).first)
    else
      temp_usage = Azure::SyncTempUsageCost.where(resource_uri: azure_resource_url.try(:downcase))
      self.data.merge!('currency' => temp_usage.pluck(:currency).first)
      self.meter_data = temp_usage.pluck(:usage_costs).group_by { |cost| cost['meter_id'] }.map{ |_k, v| v.sort_by{|i| i['usage_end_time'] }.last }.map { |cost| cost.slice("resource_name", "service_name", "service_tier", "meter_id", "instance_id", "pre_tax_cost", "resource_rate","meter_name", "meter_category", "meter_sub_category", "meter_region", "usage_date_time", "quantity", "unit", "usage_end_time") unless cost['meter_sub_category'].eql?('Backup Storage') }.compact
    end
  end

  def is_costable?
    self.class::COSTABLE_SERVICES.include?(self.class.name)
  end

  state_machine initial: :pending do
    event :directory do
      transition [:pending] => :directory
    end

    event :template do
      transition [:pending, :directory] => :template
    end

    event :creating do
      transition [:pending, :directory, :template, :error] => :creating
    end

    event :created do
      transition all => :created
    end

    event :deleting do
      transition [:pending, :template, :created, :error] => :deleting
    end

    event :deleted do
      transition all => :deleted
    end

    event :modifying do
      transition [:error, :created] => :modifying
    end

    event :error do
      transition all => :error
    end

    event :reloading do
      transition [:creating, :created, :error, :deleting] => :reloading
    end
  end

  def self.get_remote_resource_formatter_klass
    name.split("Resource").join("RemoteResourceObject")
  end

  def self.get_representer_for(module_name)
    case module_name
    when :service_manager
      representer_type =
        if name.eql?('Azure::Resource::Database::SQL::DB')
          'SQLDatabase'
        else
          split_service_type = name.split('::')
          representer_type = split_service_type.include?("Database") && !split_service_type.include?("ElasticPool") ? split_service_type[-2] : split_service_type.last
        end
      "ServiceManager::Azure::Resource::#{representer_type}Representer"
    end
  end

  def self.find_with_case_insensitive_tags(s_tags, tag_operator)
    CSLogger.info "----------------------INSIDE find_with_case_insensitive_tags INSENSITIVE---------------------------"
    query = ''
    s_tags.each_with_index do |h, i|
      h["tag_sign"] = "=" if h["tag_sign"].blank?
      tag_key = h['tag_key'].gsub("'", "''")
      tag_value = h['tag_value'].nil? ? h['tag_value'] : h['tag_value'].gsub("'", "''")
      query += tag_operator if i.positive?
      query += if !tag_value.eql?(nil)
                 h["tag_sign"].eql?('=') ? " lower(provider_data ->> 'tags')::jsonb @> lower('#{{tag_key => tag_value}.to_json}')::jsonb " : "(NOT(lower(provider_data ->> 'tags'))::jsonb @> lower('#{{tag_key => tag_value}.to_json}')::jsonb) "
               else
                 (h["tag_sign"].eql?('=') ? " (lower(provider_data ->> 'tags')::jsonb @> lower('#{{tag_key => nil}.to_json}')::jsonb OR (NOT(lower(provider_data ->> 'tags'))::jsonb ?& lower('{#{tag_key}}')::text[])) " : "((NOT(lower(provider_data ->> 'tags'))::jsonb @> lower('#{{tag_key => nil}.to_json}')::jsonb) AND lower(provider_data ->> 'tags')::jsonb ?& lower('{#{tag_key}}')::text[]) ")
               end
    end
    where(query)
  end

  def self.find_with_case_sensitive_tags(s_tags, tag_operator)
    CSLogger.info "----------------------INSIDE find_with_case_sensitive_tags SENSITIVE---------------------------"
    query = ''
    s_tags.each_with_index do |h, i|
      h["tag_sign"] = "=" if h["tag_sign"].blank?
      tag_key = h['tag_key'].gsub("'", "''")
      tag_value = h['tag_value'].nil? ? h['tag_value'] : h['tag_value'].gsub("'", "''")
      query += tag_operator if i.positive?
      query += if !tag_value.eql?(nil)
                 h["tag_sign"].eql?('=') ? "(provider_data ->> 'tags')::jsonb @> '#{{tag_key => tag_value}.to_json}'" : "(NOT(provider_data ->> 'tags')::jsonb @> '#{{tag_key => tag_value}.to_json}')"
               else
                 (h["tag_sign"].eql?('=') ? "((provider_data ->> 'tags')::jsonb @> '#{{tag_key => nil}.to_json}'OR(NOT(provider_data ->> 'tags')::jsonb ?& '{#{tag_key}}'))" : "((NOT(provider_data ->> 'tags')::jsonb @> '#{{tag_key => nil}.to_json}')AND(provider_data ->> 'tags')::jsonb ?& '{#{tag_key}}')")
               end
    end
    where(query)
  end

  def self.build_ignored_categories_str(ignored_from_list)
    return "ARRAY['']" if ignored_from_list.blank?

    ignored_from_list = Array[* ignored_from_list]
    ignored_from = 'ARRAY['
    ignored_from_list.each_with_index do |ignored, i|
      ignored_from += ', ' if i.positive?
      ignored_from += "'#{ignored}'"
    end
    ignored_from += ", 'all']"
  end

end
