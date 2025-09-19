class Azure::Resource::Compute::Disk < Azure::Resource::Compute

  include Synchronizers::Azure
  include Azure::Resource::RemoteAction
  include Azure::Resource::CostCalculator

  AZURE_RESOURCE_TYPE = "Microsoft.Compute/disks".freeze

  store_accessor :data, :sku, :os_type, :disk_size_gb, :disk_iopsread_write, :disk_mbps_read_write, :disk_state, :virtual_machine
  delegate :azure_disks, to: :adapter, allow_nil: true

  alias_method :client, :azure_disks

  scope :exclude_active_sas, -> { where.not("provider_data->>'disk_state'='ActiveSAS'") }
  scope :unattached, -> { where("provider_data->>'disk_state'='Unattached'") }
  scope :attached, -> { where.not("provider_data->>'disk_state'='Unattached'") } # consider all state except Unattached
  scope :by_retention_period, -> { where("provider_data->>'time_created' < ? ", DateTime.now - 30.days) }
  scope :data_disks, -> { where("provider_data->>'os_type' is NULL") }
  scope :os_disks, -> { where.not("provider_data->>'os_type' is NULL") } 

  def build_primary_connection(**args)
    vm_id_map = args.fetch(:vm_id_map, {})
    vm_id = vm_id_map[virtual_machine] if virtual_machine.present?
    return [] if vm_id.blank?

    [find_or_initialize_connetion(vm_id, id)]
  end

  def ultra_disk?
    sku['tier'].eql?('Ultra')
  end
end
