module Parsers
  module Azure
    class Service
      require 'hash'
      
    	def initialize(remote_service_object)
        @remote_service_object = remote_service_object.deep_transform_keys_in_object { |key|
          key.to_s.underscore
        }
        @service_metadata = {
          "name" => (@remote_service_object["name"] rescue ""),
          "type" => (@remote_service_object["type"] rescue "")
        }
        CSLogger.logger.tagged("Parse service: #{@remote_service_object['name']}, type: #{Parsers::Azure::ServiceNameParser.parse_resource_type(@remote_service_object['type'])}") do 
          @attributes = parse_to_azure_service_params 
        end
    	end

      def creation_attributes
        @attributes.merge({
          CS_service_attributes: {
            state: "running",
            name: @remote_service_object["name"],
            service_type:  self.class.to_s.split("Parsers::").last,
            provider_id: get_provider_id,
            account_id: @remote_service_object["account_id"],
            adapter_id: @remote_service_object["adapter_id"],
            region_id: @remote_service_object["region_id"],
            subscription_id: @remote_service_object["subscription_id"],
            metadata: get_metadata,
            updated_at: Time.now
          }
        })
      end

      def has_associated_serices?
        false
      end

      def associated_service_parsers

      end

      def get_metadata
        {}
      end

      def get_provider_id
        id = @remote_service_object["id"]|| @remote_service_object["name"]
        "/subscriptions/#{@remote_service_object["provider_subscription_id"]}/resourceGroups/#{@remote_service_object["resource_group_name"]}/providers/#{@remote_service_object['type']}/#{id}"
      end

      def parse_to_azure_service_params
        remote_service_data = @remote_service_object
        {
          "name" => remote_service_data["name"],
          "location" => remote_service_data["location"],
          "azure_resource_type" => Parsers::Azure::Service.dig(remote_service_data, {}, "", "type"),
          # "resource_group_name" => @remote_service_object.resource_group_name,
          "adapter_id" => @remote_service_object["adapter_id"],
          "resource_group_id" => @remote_service_object["resource_group_id"],
          "region_id" => @remote_service_object["region_id"],
          "subscription_id" => @remote_service_object["subscription_id"],
          "account_id" => @remote_service_object["account_id"],
          "provider_id" => get_provider_id,
          "depends_on" => @remote_service_object["depends_on"],
          "updated_at" => Time.now,
          "tags" => remote_service_data["tags"]
      	}
      end
      
      def attributes
        @attributes
      end

      def parse_ip_configs_for_subnet_id(ip_configs)
        new_subnet_id = ""
        ip_configs.each do |ip_config|
          subnet_id = ip_config["properties"]["subnet"]["id"] rescue ""
          if subnet_id.present?
            if subnet_id.include?("/providers/Microsoft.Network/virtualNetworks/subnets/")
              new_subnet_id = subnet_id # correct subnet id format, do nothing
            else
              i = subnet_id.index("Microsoft.Network/virtualNetworks")
              new_subnet_id = "#{subnet_id[0..(i-1)]}Microsoft.Network/virtualNetworks/subnets/#{Parsers::Azure::ServiceNameParser.parse_vnet_name(subnet_id)}/#{Parsers::Azure::ServiceNameParser.parse_subnet_name(subnet_id)}"
            end
            break if new_subnet_id.present?
          end
        end
        ip_configs.map{|ip_config| ip_config["properties"].merge!({"subnet" => {"id" => new_subnet_id}})} if new_subnet_id.present?
        ip_configs
      end

      def self.dig(hash_to_dig, metadata, default_val, key, *path)
        begin
          value = hash_to_dig[key]
          if value.nil? && !path.empty? #in between key was not present
            CSLogger.warn "Missing property #{key} for service: #{metadata['name']}(#{metadata['type']}), trace: #{caller[0]} "
            return default_val
          elsif path.empty? #we reached at the last level
            if value.nil? # last level key was not present or actual value is nil
              CSLogger.warn "Missing property #{key} for service: #{metadata['name']}(#{metadata['type']}), trace: #{caller[0]} " 
              return default_val
            elsif default_val.class != value.class # class mismatch
              CSLogger.warn "Class mismatch for #{key}: #{value}- expected class= #{default_val.class}, actual class= #{value.class}, service: #{metadata['name']}(#{metadata['type']}), trace: #{caller[0]} " 
              return default_val
            end
            return value # valid value so return it
          elsif value.is_a?(Hash)
            dig(value, metadata, default_val, *path)
          end
        rescue Exception => e
          CSLogger.error "Something went wrong in dig method: #{e.class}, #{e.message}, #{e.backtrace}"
          return default_val
        end
      end
    end
  end
end