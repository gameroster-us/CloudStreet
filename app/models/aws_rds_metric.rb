# frozen_string_literal: true

# Store AWSRdsMetric details for rightsizing
class AWSRdsMetric
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :name, type: String
  field :provider_id, type: String
  field :region_code, type: String
  field :engine, type: String
  field :instance_type, type: String
  field :instance_type_family, type: String
  field :tags
  field :multi_az, type: Boolean
  field :cpu, type: Integer
  field :ram
  field :license_model, type: String
  field :cost_by_hour, type: Float
  field :metric_data
  field :aws_account_id

  index({ aws_account_id: 1 })
end
