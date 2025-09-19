# frozen_string_literal: true

module V2::Azure::ServiceManager::Resource::ElasticPoolRepresenter
  
  include Roar::JSON
  include Roar::Hypermedia
  include ServiceManager::Azure::ResourceRepresenter

  property :sku
  property :version
  property :db_status
  property :max_size_bytes
  property :sql_server_name

end

