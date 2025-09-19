module ServiceManager
  module Azure
    module Resource
      module SecurityGroupRepresenter
        include Roar::JSON
        include Roar::Hypermedia
        include ServiceManager::Azure::ResourceRepresenter

        property :security_rules
        property :network_interfaces
        property :default_security_rules
      end
    end
  end
end
