module V2::Tenant::AdapterListObjectRepresenter
  
  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL

  property :id
  property :name
  property :adapter_type
  property :state
  property :provider_account_id
  property :adapter_purpose
  property :is_shared, getter: -> (args) { args[:options][:current_account].try(:id) != account_id }

  def adapter_type
    type.to_s.gsub('Adapters::','')
  end

  def provider_account_id
    if is_aws?
      aws_account_id
    elsif is_azure?
      subscription_id
    elsif is_gcp?
      project_id
    end
  end

end