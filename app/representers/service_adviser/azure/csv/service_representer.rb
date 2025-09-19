module ServiceAdviser::Azure::Csv::ServiceRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  DISK_TYPE = {
    'Standard_LRS' => 'Standard HDD(LRS)',
    'StandardSSD_LRS' => 'Standard SSD(LRS)',
    'Premium_LRS' => 'Premium SSD(LRS)',
    'StandardSSD_ZRS' => 'Standard SSD(ZRS)',
    'Premium_ZRS' => 'Premium SSD(ZRS)',
    'UltraSSD_LRS' =>'Ultra Disk(LRS)'
  }.freeze

  property :id
  property :name
  property :provider_id
  property :created_date
  property :additional_information
  property :get_monthly_estimated_cost, as: :monthly_estimated_cost, getter: ->(args) { get_monthly_estimated_cost(args[:options][:user_options][:currency_rate]) }
  property :adapter_id, getter: ->(args) { self[:adapter_id] }
  property :region_id, getter: ->(args) { self[:region_id] }
  property :days_old
  property :state
  property :get_service_tags, as: :service_tags
  property :configured_tag_key_value
  property :service_type
  property :fetch_resource_group, as: :resource_group
  property :azure_resource_group_id
  property :azure_resource_url
  property :comment_count
  property :load_balancing_rules_added, if: ->(args) { self[:type].eql?('Azure::Resource::Network::LoadBalancer') }
  property :ignore_till
  property :additional_properties
  property :usage_cost, getter: ->(args) { usage_cost(args[:options][:user_options][:currency_rate]) }
  property :currency, getter: ->(args) { currency(args[:options][:user_options][:currency_code])}

  # we require the adapter name
  # inside service Adviser API response
  # due to latest changes on adapterlist api
  property :adapter_name, getter: lambda { |*| Adapters::Azure.find_by(id: adapter_id).try(:name) }

  def id
    self[:id]
  end

  def name
    self[:name]
  end

  def provider_id
    self[:provider_id]
  end

  def created_date
    created_date = if self["provider_created_at"].present?
                     self["provider_created_at"]
                   elsif self["created_at"].present?
                     self["created_at"]
                   end
  end

  def get_monthly_estimated_cost(currency_rate)
    currency_rate = 1 if currency_rate.nil?
    # Note: We are getting wrong resource rate for some sql db database hence getting MEC lesser than actual cost
    # We don't find any solution for unit 10/ day so showing actual cost as MEC
    if type.eql?('Azure::Resource::Database::SQL::DB')
      mec = 0.0
      mec = (cost_by_hour * 24 * 30) unless cost_by_hour.blank?
      rate = mec > data['usage_cost'].to_f ? mec : data['usage_cost'].to_f
      rate * currency_rate
    else
      cost_by_hour * 24 * 30 * currency_rate unless cost_by_hour.blank?
    end
  end

  def load_balancing_rules_added
    load_balancing_rules.count > 0 ? true : false
  end

  def additional_information
    if type.eql?("Azure::Resource::Compute::VirtualMachine")
      { instance_type: vm_size, platform: os_disk["os_type"], reserved_vm: reserved_vm?}
    elsif ["Azure::Resource::Database::MySQL::Server", "Azure::Resource::Database::MariaDB::Server", "Azure::Resource::Database::PostgreSQL::Server"].include?(type)
      { tier: sku["tier"], family: sku["family"], capacity: "#{sku['capacity']} vCore(s)" }
    elsif ['Azure::Resource::Database::SQL::DB', 'Azure::Resource::Database::SQL::ElasticPool'].include?(type)
      return { tier: sku["tier"], capacity: "#{sku['capacity']} DTU(s)" } if %w[Basic Standard Premium].include?(sku["tier"])

      { tier: sku["tier"], family: sku["family"], capacity: "#{sku['capacity']} vCore(s)" }
    elsif type.eql?("Azure::Resource::Compute::Disk")
      { size: "#{disk_size_gb} GB", provisioned_IOPS: disk_iopsread_write, type: DISK_TYPE[data["sku"]["name"]] }
    elsif type.eql?('Azure::Resource::Network::LoadBalancer')
      { sku: sku }
    elsif type.eql?('Azure::Resource::Network::PublicIPAddress')
      { sku: sku, version: ip_address_version, allocation: ip_allocation_method }
    elsif type.eql?('Azure::Resource::Compute::Snapshot')
      { disk_size_gb: disk_size_gb, source_disk: (creation_data['source_resource_id'] || creation_data['source_uri'])&.split('/')&.last || ''}
    elsif type.eql?('Azure::Resource::Web::AppServicePlan')
      (sku&.slice('size', 'capacity', 'tier') || {}).merge({ platform: os, no_of_apps: apps })
    end
  end

  def days_old
    if (type.eql?('Azure::Resource::Compute::Snapshot') || type.eql?('Azure::Resource::Compute::Disk')) && provider_data['time_created'].present?
      (Time.now - Time.find_zone('UTC').parse(provider_data['time_created'])).to_i / (24 * 60 * 60)
    elsif self['provider_created_at'].present?
      (Time.now - self['provider_created_at']).to_i / (24 * 60 * 60)
    elsif self['created_at'].present?
      (Time.now - self['created_at']).to_i / (24 * 60 * 60)
    end
  end

  def state
    type = self.type.split("::")
    if type.include?("VirtualMachine")
      vm_status
    elsif type.include?("Database")
      db_status
    elsif type.include?("Disk")
      disk_state
    elsif type.include?('Snapshot')
      provisioning_state
    elsif type.include?('LoadBalancer')
      self.provider_data['backend_address_pools'].present? ? 'Associated' : 'Unassociated'
    elsif type.include?('AppServicePlan')
      status
    end
  end

  def get_service_tags
    try(:tags)
  end

  def configured_tag_key_value
    try(:tags)
  end

  def service_type
    type = self.type.split("::")
    return type[-2] if type.include?("Database") && !type.include?('ElasticPool')

    type[-1]
  end

  def fetch_resource_group
    self.resource_group.name
  end

  def usage_cost(curreny_rate)
    currency_rate = 1 if currency_rate.nil?
    data['usage_cost'].to_f * currency_rate
  end

  def currency(currency_code)
    currency_code.nil? ? 'USA' : currency_code
  end
end
