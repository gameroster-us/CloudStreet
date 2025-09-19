module EncryptionKeyRepresenter
include Roar::JSON
include Roar::Hypermedia
  
  property :adapter, extend: AdapterDisplayRepresenter
  property :region, extend: RegionInfoRepresenter
  property :key_alias
  property :key_id
  property :arn
  property :enabled
  property :state
  property :creation_date, getter: lambda { |*| creation_date.strftime CommonConstants::DEFAULT_TIME_FORMATE unless creation_date.nil? }
  property :account_id

  # we require the adapter name and is_shared_adapter info
  # inside service manager API response due to latest changes on adapter
  # list api
  property :adapter_name, getter: lambda{ |*| adapter.name }
  property :is_shared_adapter, getter: ->(args) { adapter.is_shared_adapter(args[:options][:current_account].try(:id)) }
end
