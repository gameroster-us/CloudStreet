class Azure::CostUpdaterWorker
  include Sidekiq::Worker
  sidekiq_options queue: :azure_idle_queue, backtrace: true

  def perform(options)
    CSLogger.info "stared setting hourly cost for ---> #{options['klass']}"
    resources = Azure::Resource.where(id: options['azure_resource_group_ids']).active.find_in_batches(batch_size: 100) do |resource_groups|
      results = resource_groups.each_with_object([]) do |azure_resource, memo|
        begin
          CSLogger.info "Resource name ->>> #{azure_resource.name}"
          azure_resource.set_meter_data
          azure_resource.set_hourly_cost
          memo << azure_resource
        rescue StandardError => e
          CSLogger.error "====== Error for resource : #{azure_resource.name} --- Error : #{e.message} ======"
          next
        end
      end
      Azure::Resource::Importer.call(results) if results.any?
    end
    CSLogger.info "completed setting hourly cost for ---> #{options['klass']}"
  rescue StandardError => e
    CSLogger.error e.message
    CSLogger.error e.backtrace
  end

end
