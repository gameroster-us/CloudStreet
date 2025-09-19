module ServiceManager
  module Azure
    module Resource
      module SQLRepresenter
        include Roar::JSON
        include Roar::Hypermedia
        include ServiceManager::Azure::ResourceRepresenter
        include ServiceManager::Azure::Resource::DatabaseCommonProperties
      end
    end
  end
end
