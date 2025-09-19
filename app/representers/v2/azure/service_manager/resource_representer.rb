module V2::Azure::ServiceManager::ResourceRepresenter
  
  include Roar::JSON
  include Roar::Hypermedia

  property :id
  property :name
  property :provider_id
  property :adapter_id
  property :azure_resource_group_id, as: :resource_group_id
  property :resource_group_name
  property :adapter_name
  property :region_name
  property :region_id
  property :tags
  property :cost_by_hour
  property :state
  property :mec, getter: ->(args) { mec(args[:options][:user_options][:current_tenant_currency][1]) }
  property :currency, getter: ->(args) { args[:options][:user_options][:current_tenant_currency][0] }

  # we require the adapter name and is_shared_adapter info
  # inside service manager API response due to latest changes on adapter
  # list api
  property :adapter_name, getter: lambda{ |*| adapter.name }
  property :is_shared_adapter, getter: ->(args) { adapter.is_shared_adapter(args[:user_options][:current_account].try(:id)) }

  def mec(rate)
    represented.cost_by_hour * 24 * 30 * rate
  end
  
end
