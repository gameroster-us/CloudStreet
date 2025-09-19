# frozen_string_literal: false

module Azure
  # Worker to add retail price to
  # Non reserved Vms
  class NonReservedVmCostUpdaterWorker
    include Sidekiq::Worker
    sidekiq_options queue: :azure_idle_queue, backtrace: true

    def perform(adapter_id)
      adapter = Adapter.find_by(id: adapter_id)
      return unless adapter.present?

      region_vms = Azure::Resource::Compute::VirtualMachine.where(adapter_id: adapter.id, cost_by_hour: 0.0)
                                                           .active
                                                           .exclude_stopped_deallocated
                                                           .non_reserved_vms
                                                           .group_by(&:region_id)
      region_vms.each do |region_id, vms|
        region = Region.find_by(id: region_id)
        next if region.blank?

        Azure::NonReservedVmCostUpdater.new(region, vms).start_updating
      end
      CSLogger.info "Retail price added to non reserved Azure VMs of adapter - #{adapter.name}"
    end
  end
end
