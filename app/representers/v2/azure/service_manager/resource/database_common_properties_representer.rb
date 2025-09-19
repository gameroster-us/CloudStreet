module V2::Azure::ServiceManager::Resource::DatabaseCommonPropertiesRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  property :sku
  property :version
  property :db_status
  property :domain_name
  property :ssl_enforcement
  property :storage_size_in_mb
  property :backup_retention_days
end

