module V2::Azure::ServiceManager::Resource::SubnetRepresenter
  
  include Roar::JSON
  include Roar::Hypermedia
  include ServiceManager::Azure::ResourceRepresenter

  property :address_prefixes
  property :ip_configurations
  property :vnet_name
  
end

