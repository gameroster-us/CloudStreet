module V2::GCP::AdapterListObjectRepresenter

  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL

  property :id
  property :name
  property :state
  property :adapter_purpose
  property :sync_state, if: lambda { |args| adapter_purpose.eql?('normal') }
  property :currency
  property :is_shared, getter: -> (args) { args[:options][:current_account].try(:id) != account_id }
  property :gcp_report_configuration, if: lambda { |args| adapter_purpose.eql?('billing') }
  property :dataset_id, if: lambda { |args| adapter_purpose.eql?('billing') }
  property :table_name, if: lambda { |args| adapter_purpose.eql?('billing') }
  property :gcp_project_id
  property :margin_discount_calculation

end