class Azure::Resource::Network::Subnet < Azure::Resource::Network

  include Synchronizers::Azure
  include Azure::Resource::RemoteAction

  AZURE_RESOURCE_TYPE = "Microsoft.Network/subnet".freeze

  store_accessor :data, :address_prefixes, :ip_configurations, :vnet_name
  delegate :azure_subnets, to: :adapter, allow_nil: true

  alias_method :client, :azure_subnets

  def build_primary_connection(**args)
    vnet_id_map = args.fetch(:vnet_id_map, {})
    vnet_id = vnet_id_map[net_name] if vnet_name.present?
    return [] if vnet_id.blank?

    [find_or_initialize_connetion(vnet_id, id)]
  end

end
