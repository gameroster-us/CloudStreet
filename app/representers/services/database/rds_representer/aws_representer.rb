module Services
  module Database
    module RdsRepresenter
      module AWSRepresenter
        include Roar::JSON
        include Roar::Hypermedia
        include ServicesRepresenter
        include RdsRepresenter
        include ServiceBackupable::AWS::Representer

        # attributes from data #listattributes
        property :port
        property :provider_vpc_id
        property :engine
        property :multi_az
        property :flavor_id
        property :endpoint
        property :provider_security_groups_info, as: :db_security_groups

        property :cluster_id
        property :priority

        # attibutes from provider_data
        property :engine_version
        property :list_attributes

        nested :config_details do
          property :master_username
          property :storage_type
          property :iops
          property :allocated_storage
          property :db_parameter_groups
          property :dbi_resource_id
          property :created_at, as: :created_time, getter: lambda { |args| self.provider_created_at.getutc.to_s rescue "" }
          property :storage_encrypted
          property :encryption_key_alias
        end

        nested :network_and_security do
          property :availability_zone
          property :db_subnet_group_name
          property :publicly_accessible
          property :ca_certificate_id
          property :get_associated_vpc, as: :vpc # need to fetch
          property :get_associcated_subnets, as: :subnets # need to fetch
          property :get_vpc_security_groups, as: :vpc_security_groups
        end

        nested :backup_and_maintenance do
          property :backup_window
          property :maintenance_window
          property :backup_retention_period
          property :get_auto_minor_version_upgrade, as: :auto_minor_version_upgrade
          property :preferred_maintenance_window
          property :preferred_backup_window
          property :get_pending_modified_values, as: :pending_modified_values
        end

        nested :availability_and_durability do
          property :db_instance_status
          property :last_restorable_time
        end

        nested :version_selection do
          property :version_list
          property :instance_list
        end

        property :state
        property :tags
        property :service_tags
        property :vpc_id
        property :subnet_group_ids
        property :supported_encryption_flavors
        property :option_groups, getter: lambda{|args| self.provider_data['db_parameter_groups'].first['DBParameterGroupName'] rescue ""}
        property :license_model, getter: lambda{|args| self.provider_data['license_model'] rescue ""}

        def encryption_key_alias
          return nil unless self.storage_encrypted && self.data['kms_key_id']
          encryption_key = EncryptionKey.find_by_key_id self.kms_key_id
          encryption_key.try :key_alias
        end

        def get_pending_modified_values
          self.pending_modified_values.blank? ? "NA" : self.pending_modified_values
        end

        def get_vpc_security_groups
          provider_data["vpc_security_groups"] rescue []
        end

        def get_auto_minor_version_upgrade
          self.auto_minor_version_upgrade
        end

        def subnet_group_ids
          fetch_remote_services(Protocols::SubnetGroup).map { |remote_service| remote_service.provider_id || remote_service.name }
        end

        def get_associated_vpc
          fetch_remote_services(Protocols::Vpc).map { |remote_service| remote_service.provider_id || remote_service.name } rescue []
        end

        def get_associcated_subnets
          associated_subnet_group = fetch_remote_services(Protocols::SubnetGroup).first
          associated_subnet_group.fetch_remote_services(Protocols::Subnet).map { |remote_service| remote_service.provider_id || remote_service.name } if associated_subnet_group
        end

        def vpc_id
          interfaces.of_type(Protocols::Vpc).first.remote_interfaces.first.service.data["vpc_id"] rescue nil
        end

        alias provider_vpc_id vpc_id

        def preferred_maintenance_window
          self.prepare_preferred_maintenance_window(self.preferred_maintenance_window_day, self.preferred_maintenance_window_hour, self.preferred_maintenance_window_minute, self.preferred_maintenance_window_duration)
        end

        def preferred_backup_window
          self.prepare_prefered_backup_window(self.preferred_backup_window_hour, self.preferred_backup_window_minute, self.preferred_backup_window_duration)
        end

        def version_list
          # Services::Database::Rds::AWS::ENGINE_VERSIONS_MAP[self.engine][get_region_code].sort
          self.get_available_versions
        end

        def instance_list
          # Services::Database::Rds::AWS::ENGINE_FLAVOR_ID_MAP[self.engine][get_region_code]
          self.get_available_flavours
        end

        def list_attributes
          ['name', 'endpoint', 'engine', 'engine_version', 'flavor_id', 'multi_az', 'state']
        end

        def get_region_code
          self.region.code || self.availability_zone.delete(self.availability_zone.last)
        end

        def supported_encryption_flavors
          self.class::SUPPORTED_FLOVOR_IDS_FOR_ENCRYPTED_RDS
        end
      end
    end
  end
end
