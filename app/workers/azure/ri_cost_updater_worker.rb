# frozen_string_literal: false

module Azure
  # Worker to update Azure Reserved VM cost
  class RICostUpdaterWorker
    include Sidekiq::Worker
    sidekiq_options queue: :azure_idle_queue, backtrace: true

    def perform(adapter_id)
      adapter = Adapter.find_by(id: adapter_id)
      return if adapter.blank?

      CSLogger.info "=== Started Updating Reserved VM cost for adapter : #{adapter.name}"
      CurrentAccount.client_db = adapter.account
      Azure::Resource::CostCalculators::Compute::ReservedInstances::VirtualMachine.new(adapter)
                                                                                  .start_updating_cost
      puts "=== Completed Updating Reserved VM cost for adapter : #{adapter.name}"
   end
  end
end
