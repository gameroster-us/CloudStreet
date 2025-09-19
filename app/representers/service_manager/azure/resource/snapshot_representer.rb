module ServiceManager
  module Azure
    module Resource
      module SnapshotRepresenter
        include Roar::JSON
        include Roar::Hypermedia
        include ServiceManager::Azure::ResourceRepresenter

        property :sku
        property :creation_data
        property :disk_size_gb
        property :provisioning_state
      end
    end
  end
end
