module Services
  module Compute
    module ServerRepresenter
      module AWSRepresenter
        include Roar::JSON
        include Roar::Hypermedia
        include Roar::JSON::HAL
        include ServicesRepresenter
        # include ServerRepresenter
        include ServiceBackupable::AWS::Representer

        # attributes from data
        property :image_id, as: :ami_id
        property :flavor_id
        property :status_checks

        # attributes from provider_data
        property :private_dns_name, getter: lambda{|args| self.parsed_provider_data["private_dns_name"] rescue ""}
        property :private_ip_address, getter: lambda{|args| self.parsed_provider_data["private_ip_address"] rescue ""}
        property :kernel_id, getter: lambda { |*| self.parsed_provider_data["kernel_id"] rescue "" }
        property :ip_address, getter: lambda { |*| self.parsed_provider_data["ip_address"] rescue "" }
        property :vpc_id, getter: lambda { |*| self.parsed_provider_data["vpc_id"] rescue "" }
        property :subnet_id, getter: lambda { |*| self.parsed_provider_data["subnet_id"] rescue "" }
        property :source_dest_check, getter: lambda { |*| self.parsed_provider_data["source_dest_check"] rescue "" }
        property :security_group_ids
        property :availability_zone, getter: lambda { |*| self.parsed_provider_data["availability_zone"] rescue "" }
        property :image_config_id
        property :ebs_optimized, getter: lambda { |*| self.parsed_provider_data["ebs_optimized"] rescue "" }
        property :monitoring
        property :key_name
        property :decrypted_password
        property :platform
        collection :volumes, extend: Environments::Services::Compute::ServerRepresenter::VolumeRepresenter::AWSRepresenter
        property :iscsi_volumes
        property :elastic_ip
        property :iam_role
        property :is_asg_server

        property :registered
        property :tags
        property :disable_api_termination
        property :up_time
        property :start_time
        property :created_time
        property :provider_created_at, as: :launch_time, getter: lambda { |args| self.provider_created_at.getutc.to_s rescue "" }

        property :get_delete_on_termination, as: :termination_protection
        property :get_network_interfaces, as: :network_interfaces
        property :owner, getter: lambda { |*| self.parsed_provider_data["tags"]["owner"] rescue "" }
        property :vpc, getter: lambda { |*| self.vpc rescue "" }
        property :subnet

        def get_delete_on_termination
          self.provider_data["block_device_mapping"].first["deleteOnTermination"] rescue ""
        end

        def get_network_interfaces
          self.provider_data["network_interfaces"].first["networkInterfaceId"] rescue ""
        end

        link :download do
          key_pair = account.resources.key_pairs.where(name: self.key_name, adapter: adapter, region: region_id).first
          if key_pair.present?
            download_keys_key_pair_path(key_pair[:id]) if  key_pair && key_pair.data["key"].present?
          end
        end

        def security_group_ids
            self.get_security_groups.map{|s| {id: s.id, name: s.name, group_id: s.data['group_id']}}
        end
           
        def platform
          organisation_image.try(:platform)
        end 

        def volumes
          self.attached_volumes
        end 

        def iscsi_volumes
          self.server_attached_iscsi_volumes
        end 

        def elastic_ip
          self.server_elastic_ip
        end

        def subnet
          self.server_subnet
        end
      end
    end
  end
end  
