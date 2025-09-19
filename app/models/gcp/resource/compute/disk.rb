class GCP::Resource::Compute::Disk < GCP::Resource::Compute
  include Synchronizers::GCP
  include GCP::Resource::RemoteAction
  include GCP::Resource::CostCalculator
  
  store_accessor :data, :disk_size_gb, :disk_type, :source_image, :source_image_id, :disk_storage_type, :disk_state, :disk_vm, :location_type

  ACTIVE_STATUS = %i[creating restoring ready failed deleting]

  scope :active, -> { where(state: ACTIVE_STATUS) }

  class << self
    def select_running_vm_disks(services)
      service_ids = []
      services.each do |service|
        res = GCP::Resource::Compute::VirtualMachine.where(name: service.disk_vm, adapter_id: service.adapter.id).active
        service_ids << service.id if res.first.try(:vm_status) == 'running'
      end
      GCP::Resource::Compute::Disk.where(id: service_ids)
    end
  end

end