# frozen_string_literal: true

module Azure
  # Worker to update add retail cost
  # in Azure resources
  class ResourceRetailCostUpdaterWorker
    include Sidekiq::Worker
    sidekiq_options queue: :azure_idle_queue, retry: false, backtrace: true

    def perform(options)
      adapter = Adapter.find_by(id: options['adapter_id'])
      return if adapter.blank?

      begin
        resource_klass = options['resource_type'].split('::').last

        resources = options['resource_type'].constantize
                                            .where(adapter_id: adapter.id, cost_by_hour: 0.0)
                                            .exclude_aks_resource_group_services
                                            .exclude_databricks_resource_group_services
                                            .active

        resources = resources.exclude_stopped_deallocated.non_reserved_vms if resource_klass.eql?('VirtualMachine')
        resources = resources.exclude_free_tier if resource_klass.eql?('AKS')
        initiate_cost_updater_service(resources, resource_klass)
      rescue StandardError => e
        CSLogger.error e.message
        CSLogger.error e.backtrace
      end
    end

    def initiate_cost_updater_service(resources, resource_klass)
      resources.group_by(&:region_id).each do |region_id, region_resources|
        cost_updater = "Azure::RetailCostUpdaters::#{resource_klass}".constantize.new(region_id, region_resources)
        cost_updater.start_updating
      end
    end
  end
end
