module V2::Azure::ServiceManager::Resource::SnapshotRepresenter
  
  include Roar::JSON
  include Roar::Hypermedia
  include ServiceManager::Azure::ResourceRepresenter

  property :sku
  property :creation_data
  property :disk_size_gb
  property :provisioning_state

end
