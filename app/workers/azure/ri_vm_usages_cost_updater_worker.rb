# frozen_string_literal: false

module Azure
  # Worker to update Azure Reserved VM cost by Usages cost API
  class RIVmUsagesCostUpdaterWorker
    include Sidekiq::Worker
    sidekiq_options queue: :azure_idle_queue, backtrace: true

    def perform(adapter_id)
      adapter = Adapter.find_by(id: adapter_id)
      return if (adapter.blank? || !adapter.ea_adapter?) 
      CSLogger.info "=== Started Updating Reserved VM cost from usages API for adapter : #{adapter.name}"
      region_vms = Azure::Resource::Compute::VirtualMachine.includes(:region).where(adapter_id: adapter.id).active.exclude_stopped_deallocated

      region_vms = region_vms.select{|vm| vm.cost_by_hour.eql?(0.0) || vm.reserved_vm? }.group_by(&:region_code)
      region_vms.each do |region_code, vms|
        Azure::Resource::CostCalculators::Compute::ReservedInstances::VmCostUpdaterFromUsages.new(region_code, vms, adapter).start_updating_cost
      end
    end
  end
end
