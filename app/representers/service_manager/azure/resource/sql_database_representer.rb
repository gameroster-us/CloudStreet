module ServiceManager
  module Azure
    module Resource
      module SQLDatabaseRepresenter
        include Roar::JSON
        include Roar::Hypermedia
        include ServiceManager::Azure::ResourceRepresenter
        include ServiceManager::Azure::Resource::DatabaseCommonProperties

        property :current_sku
        property :max_size_bytes
        property :sql_server_name
        property :current_service_objective_name
        property :elastic_pool_info
      end
    end
  end
end
