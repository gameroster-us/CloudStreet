module Azure
  class PriceSheetFetcherWorker
    include Sidekiq::Worker
    sidekiq_options queue: :azure_sync, :retry => 10, backtrace: true

    def perform
      ea_adapters = Adapters::Azure.includes(:subscription).select{|a| a.ea_adapter? && a.subscription.present? }.pluck(:id)
      return if ea_adapters.blank?
      adapter_id = ea_adapters.first
      options = {adapter_id: [adapter_id]}
      adapter_batch = Sidekiq::BatchCreator.call(Azure::PriceSheetCallback, options, "procees for adapter- #{adapter_id}")
      adapter_batch.jobs do
       Azure::AdapterPriceSheetFetcherWorker.perform_async(adapter_id)
      end
    end
  end

  class PriceSheetCallback
    def on_complete(status, options)
      CSLogger.info "Azure pricesheet fetching completed for adapter-- #{options["adapter_id"]}"
      exclude_account_ids = []
      exclude_account_ids << options["adapter_id"]
      uniq_ea_adapter_ids = Adapters::Azure.includes(:subscription).where.not(id: options['adapter_id']).select{|a| a.ea_adapter? &&  a.subscription.present? }.pluck(:id)
      adapter_id = uniq_ea_adapter_ids.first
      if adapter_id.present?
        exclude_account_ids << uniq_ea_adapter_ids.first
        options["adapter_id"] = exclude_account_ids.flatten
        adapter_batch = Sidekiq::BatchCreator.call(Azure::PriceSheetCallback, options, "procees for adapter- #{adapter_id}")
        adapter_batch.jobs do
          Azure::AdapterPriceSheetFetcherWorker.perform_async(adapter_id)
        end
      else
        CSLogger.info "Pricesheet fetch and store for all EA adapter"
      end
    end
    
    def on_success(status, options)
    end
  end

end

