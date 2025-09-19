module SynchronizationRepresenter
include Roar::JSON
include Roar::Hypermedia

  property :id
  property :started_at, getter: lambda { |*| started_at.strftime CommonConstants::DEFAULT_TIME_FORMATE }
  property :has_synced_vpcs
  property :adapter_names
  property :region_names
  property :completed_at, getter: lambda { |*| completed_at.strftime CommonConstants::DEFAULT_TIME_FORMATE }
  property :state_info
  property :account_id
  property :created_at, getter: lambda { |*| created_at.strftime CommonConstants::DEFAULT_TIME_FORMATE }
  property :updated_at, getter: lambda { |*| updated_at.strftime CommonConstants::DEFAULT_TIME_FORMATE }
  property :friendly_id
end
