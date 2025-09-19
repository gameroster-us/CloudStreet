class Azure::Resource::Database::SQL::ElasticPool < Azure::Resource::Database::SQL
	
  include Synchronizers::Azure
  include Azure::Resource::RemoteAction
  include Azure::Resource::CostCalculator

  AZURE_RESOURCE_TYPE = "Microsoft.Sql/servers/elasticpools".freeze
  LICENSE_TYPE_IDENTIFIER = 'LicenseIncluded'

  store_accessor :data, :sku, :version, :max_size_bytes, :db_status, :creation_date, :zone_redundant, :sql_server_name
  delegate :azure_sql_server, to: :adapter, allow_nil: true
  alias_method :client, :azure_sql_server

  scope :vcore_pool, -> { where("provider_data->>'kind' ILIKE '%vcore%'") }
  scope :license_cost_included, -> { where("lower(provider_data->>'license_type')=?", LICENSE_TYPE_IDENTIFIER.downcase) }
  scope :ahub_eligible_elastic_pool, -> { vcore_pool.license_cost_included }

  def vcore_based_pool?
    provider_data['kind'].downcase.include?('vcore')
  end

  def storage_size_in_mb
    # convert bytes to MB
    (try(:max_size_bytes) || 1) / (1024 * 1024)
  end

  def capacity
    sku.try(:[], 'capacity').try(:to_f)
  end
end
