module V2::Azure::ServiceManager::Resource::PublicIPAddressRepresenter

  include Roar::JSON
  include Roar::Hypermedia
  include ServiceManager::Azure::ResourceRepresenter

  property :sku
  property :ip_allocation_method
  property :ip_address_version
  property :idle_timeout_in_minutes
  property :ip_configuration
  
end

