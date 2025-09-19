module Services
  module Network
    module ElasticIPRepresenter
      module AWSRepresenter
include Roar::JSON
include Roar::Hypermedia
        include ServicesRepresenter
        include ElasticIPRepresenter
        
        # attributes from data
        
        # attibutes from provider_data
        property :server_id
        property :server_id, getter: lambda { |args| self.parsed_provider_data['server_id'] rescue "" }
        property :network_interface_id, getter: lambda { |args| self.parsed_provider_data['network_interface_id'] rescue "" }
        property :vpc_id, getter: lambda { |args| self.environment.services.find_by_provider_id(self.parsed_provider_data['server_id']).fetch_remote_services(Protocols::Vpc).first.provider_id rescue "" }
        property :public_ip, getter: lambda { |args| self.parsed_provider_data['public_ip'] rescue "" }
        property :private_ip, getter: lambda { |args| 
          self.environment.services.network_interfaces.where(provider_id: self.parsed_provider_data["network_interface_id"]).first.private_ips.find{|pip| pip["elasticIp"].eql?(self.id)}["privateIpAddress"] rescue "" 
        }
        property :public_dns, getter: lambda { |args| self.environment.services.find_by_provider_id(self.parsed_provider_data['server_id']).data['dns_name'] rescue "" }
        property :allocation_id
        property :domain, getter: lambda { |args| self.parsed_provider_data['domain'] rescue "" }

        property :list_attributes
        property :tags
        
        def list_attributes
          ['name', 'state', 'server_id', 'public_ip', 'domain','network_interface_id']
        end
      end
    end
  end
end
