module SnapshotRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  include ServiceBackupable::AWS::Representer

  property :id
  property :name
  property :provider_id
  property :type, getter: lambda { |*| 'Snapshot' }
  property :category
  property :description
  property :region_code
  property :archived
  property :min_size, getter: lambda { |args| provider_data && provider_data['volume_size'] }
  property :snapshot_type
  property :state
  property :vpc
  property :db_identifier, getter: lambda { |args| provider_data && (provider_data['DBInstanceIdentifier']||provider_data['id']) }
  property :engine
  property :status, getter: lambda { |args| provider_data && (provider_data['Status']|| provider_data['state']) }
  property :port, getter: lambda { |args| provider_data && (provider_data['Port']||provider_data['port']) }
  property :storage_size, getter: lambda { |args| provider_data && (provider_data['AllocatedStorage']||provider_data['allocated_storage']) }
  property :storage_type, getter: lambda { |args| service.try :storage_type }
  property :creation_time, getter: lambda { |args| created_at.strftime CommonConstants::DEFAULT_TIME_FORMATE  }
  property :error_message
  property :tags
  property :service_tags
  property :engine_version
  property :instance_classes , if: lambda { |args| args[:options][:with_instance_class].eql?(true) }
  property :encrypted
  property :get_rds_kms_key_id, as: :kms_key_id
  property :get_volume_kms_key_id, as: :key_id
  property :get_cost_for_current_month_till_now, as: :cost_to_date
  property :get_estimate_for_current_month, as: :current_month_estimate

  def get_rds_kms_key_id
    return unless self.kms_key_id
    if self.kms_key_id.include?('/')
      self.kms_key_id.split('/').last
    else
      self.kms_key_id
    end
  end
  def get_volume_kms_key_id
    return unless self.key_id
    if self.key_id.include?('/')
      self.key_id.split('/').last
    else
      self.key_id
    end
  end


  def engine
    provider_data &&( provider_data['Engine']||provider_data['engine'])
  end

  def engine_version
    provider_data && (provider_data['EngineVersion']||provider_data['engine_version'])
  end

  def instance_classes
    Services::Database::Rds::AWS::ENGINE_FLAVOR_ID_MAP[engine][region_code][engine_version]
  end
end
