# frozen_string_literal: true

module ServiceManager
  module Azure
    module Resource
      # ElasticPool representer
      module ElasticPoolRepresenter
        include Roar::JSON
        include Roar::Hypermedia
        include ServiceManager::Azure::ResourceRepresenter

        property :sku
        property :version
        property :db_status
        property :max_size_bytes
        property :sql_server_name
  
      end
    end
  end
end
