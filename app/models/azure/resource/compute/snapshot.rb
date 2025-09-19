class Azure::Resource::Compute::Snapshot < Azure::Resource::Compute
  include Synchronizers::Azure
  include Azure::Resource::RemoteAction
  include Azure::Resource::CostCalculator

  AZURE_RESOURCE_TYPE = "Microsoft.Compute/snapshots".freeze

  store_accessor :data, :sku, :creation_data, :disk_size_gb, :provisioning_state
  delegate :azure_snapshots, to: :adapter, allow_nil: true
  scope :by_retention_period, -> (retention_period) { where("provider_data->>'time_created' < ? ", DateTime.now - retention_period.days) }

  alias_method :client, :azure_snapshots

  # def build_primary_connection(**args)
  #   vm_id_map = args.fetch(:vm_id_map,{})
  #   vm_id = vm_id_map[self.virtual_machine] if self.virtual_machine.present?
  #   return [] if vm_id.blank?
  #   [find_or_initialize_connetion(vm_id, self.id)]
  # end
end
