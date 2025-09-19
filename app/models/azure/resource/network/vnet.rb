class Azure::Resource::Network::Vnet < Azure::Resource::Network

  include Synchronizers::Azure
  include Azure::Resource::RemoteAction

  AZURE_RESOURCE_TYPE = "Microsoft.Network/virtualNetworks".freeze

  store_accessor :data, :address_prefixes, :subnets, :enable_ddos_protection, :enable_vm_protection

  delegate :azure_virtual_networks, to: :adapter, allow_nil: true

  alias_method :client, :azure_virtual_networks

end
