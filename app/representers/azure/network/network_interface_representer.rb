module Azure
  module Network
    module NetworkInterfaceRepresenter
      include Roar::JSON
      include Roar::Hypermedia
      include AzureServicesRepresenter

      property :network_security_group_name
      property :subnet
      property :ip_configs
      # property :dns_servers
      property :dns_settings
      # property :mac_address
      property :enable_ip_forwarding
      property :category

      def category
        "Network"
      end  

      def ip_configs
        configs = self.ip_configurations
        configs.map{|ip_config|
          if ip_config["properties"]
            ip_config.merge!(ip_config.delete("properties"))
          end
          ip_config
        }
        configs.each{|config| config["public_ip_address"] = Parsers::Azure::ServiceNameParser.parse_public_ip_address(config["public_ip_address"]["id"]) rescue ""}
        configs
      end

      def subnet
        subnet = ""
        ip_configs = self.ip_configurations
        ip_configs.each do |config|
          if config["properties"].has_key? "subnet"
            subnet = Azure::Network::Subnet.parse_subnet_name(config["properties"]["subnet"]["id"])
            break
          end
        end
        subnet
      end

      def network_security_group_name
      	Parsers::Azure::ServiceNameParser.parse_sg_name(self.security_group) rescue ""
      end


      # def dns_servers
      # 	# dns_servers = {}
      # 	# dns_servers["primary_dns_server"] = data["dns_servers"][0] if data["dns_servers"].present?
      # 	# dns_servers["secondary_dns_server"] = data["dns_servers"][1] if data["dns_servers"].present?
      # 	# data["dns_servers"] = [dns_servers]
      # end

      # def virtual_machine
      #   virtual_machine_id.blank? ? "" : Parsers::Azure::ServiceNameParser.parse_vm_name(virtual_machine_id)
      # end
    end
  end
end  
