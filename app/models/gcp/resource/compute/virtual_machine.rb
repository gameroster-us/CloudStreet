# GCP resources for virtual machine
class GCP::Resource::Compute::VirtualMachine < GCP::Resource::Compute
  include Synchronizers::GCP
  include GCP::Resource::RemoteAction
  include GCP::Resource::CostCalculator

  store_accessor :data, :vm_machine_type, :disk, :vm_status , :cpu, :ram, :location_type, :attached_disk_price
  
  scope :stopped_vm,  -> { where("data->>'vm_status'='stopped'") }
  scope :running_vm,  -> { where("data->>'vm_status'='running'") }

  ACTIVE_STATUS = %i[provisioning staging running stopping reparing terminated suspending suspended]

  scope :active, -> { where(state: ACTIVE_STATUS) }

end
