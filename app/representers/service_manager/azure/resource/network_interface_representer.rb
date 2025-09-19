module ServiceManager
  module Azure
    module Resource
      module NetworkInterfaceRepresenter
        include Roar::JSON
        include Roar::Hypermedia
        include ServiceManager::Azure::ResourceRepresenter

        property :network_security_group
        property :ip_configurations
        property :enable_ipforwarding
        property :enable_accelerated_networking
        property :dns_settings
      end
    end
  end
end
