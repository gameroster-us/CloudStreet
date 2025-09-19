class Azure::SyncTempUsageCost
	include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :subscription_id
  field :resource_uri
  field :usage_costs
  field :resource_type
  field :currency

  #index field
  index({ subscription_id: 1 })
  index({ resource_uri: 1 })
  index({ resource_type: 1 })
end