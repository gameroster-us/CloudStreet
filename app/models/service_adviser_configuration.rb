class ServiceAdviserConfiguration
  include Mongoid::Document
  index({ account_id: 1 }, unique: true)

  field :running_rightsizing_config_check, type: Boolean, default: true
  field :stopped_rightsizing_config_check, type: Boolean, default: true
  field :rds_snapshot_config_check, type: Boolean, default: true
  field :volume_snapshot_config_check, type: Boolean, default: true
  field :ami_config_check, type: Boolean, default: true
  field :rds_snapshot_retention_period, type: Integer, default: 30
  field :volume_snapshot_retention_period, type: Integer, default: 30
  field :running_rightsizing_retention_period, type: Integer, default: 2
  field :stopped_rightsizing_retention_period, type: Integer, default: 3
  field :ami_retention_period, type: Integer, default: 30
  field :account_id
  field :service_type
  field :configurable_tag_key
end
