class Azure::Resource::Network::PublicIPAddress < Azure::Resource::Network

  include Synchronizers::Azure
  include Azure::Resource::RemoteAction
  include Azure::Resource::CostCalculator

  AZURE_RESOURCE_TYPE = "Microsoft.Network/publicIPAddresses".freeze

  store_accessor :data, :sku, :ip_allocation_method, :ip_address_version, :idle_timeout_in_minutes, :ip_configuration, :nat_gateway
  delegate :azure_public_ip_addresses, to: :adapter, allow_nil: true
  scope :unassociated, -> { where("provider_data->>'ip_configuration' is NULL AND provider_data->>'nat_gateway' is NULL") }
  scope :only_non_zero, -> { where.not(cost_by_hour: 0.0) }
  alias_method :client, :azure_public_ip_addresses

end
