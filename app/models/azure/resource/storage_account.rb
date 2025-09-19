class Azure::Resource::StorageAccount < Azure::Resource

  include Synchronizers::Azure
  include Azure::Resource::RemoteAction
  include Azure::Resource::CostCalculator

  AZURE_RESOURCE_TYPE = "Microsoft.Storage/storageAccounts".freeze
  BLOB_STORAGE_TYPES   =  ['Blob Storage', 'General Block Blob', 'General Block Blob v2', 'General Block Blob v2 Hierarchical Namespace', 'Premium Block Blob', 'Premium Page Blob', 'Premium Block Blob v2 Hierarchical Namespace', 'Premium Page Blob', 'Standard Page Blob', 'Standard Page Blob v2'] 
  QUEUE_STORAGE_TYPES =  ['Queues','Queues v2']
  TABLE_STORAGE_TYPES  =  ['Tables']
  FILE_STORAGE_TYPES   =  ['Files' ,'File Sync','Files v2','Premium Files']
  STORAGE_TYPES        =  BLOB_STORAGE_TYPES + QUEUE_STORAGE_TYPES + TABLE_STORAGE_TYPES + FILE_STORAGE_TYPES

  store_accessor :data, :sku, :storage_type, :primary_endpoints, :primary_location, :status_of_primary, :status_of_secondary, :secondary_location, :secondary_endpoints, :creation_time, :encryption, :access_tier, :enable_https_traffic_only, :network_rule_set
  delegate :azure_storage_account, to: :adapter, allow_nil: true

  alias_method :client, :azure_storage_account

end
