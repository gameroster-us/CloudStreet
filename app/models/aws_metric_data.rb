class AWSMetricData

  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  field :account_id
  field :adapter_id
  field :region_id
  field :provider_id
  field :metric_name
  field :time_stamp, type: DateTime
  field :used_pct
  field :created_at, type: DateTime, default: -> { Time.now }
  field :updated_at, type: DateTime, default: -> { Time.now }

  index(adapter_id: 1, region_id: 1)
  index({ adapter_id: 1, region_id: 1, provider_id: 1, metric_name: 1, time_stamp: 1 }, { name: '_adptId_regnId_prvdrId_metName_TimeStamp_' })

end
