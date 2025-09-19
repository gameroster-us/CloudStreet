class Sync::Azure::AdapterSynchronizerWorker
  include Sidekiq::Worker
  sidekiq_options queue: :azure_sync, :retry => false, backtrace: true

  def perform(adapter_id, synchronization_id = nil, queue_name = nil)
    adapter = Adapter.find_by(id: adapter_id)
    return if adapter.blank?
    enabled_region_map = Hash[Region.get_enabled_regions(adapter.account_id, :azure).pluck(:code, :id)]
    #resourceGroup deleted from remote than it will removed from exec_batch from here
    Azure::ResourceGroup.sync(adapter, enabled_region_map)
    # Store EA adapter pricesheet if not available for adapter
    adapter.subscription.reload_price_sheet if adapter.ea_adapter? && !(Azure::PriceSheet.where(subscription_id: adapter.subscription_id).exists?)
    unless (adapter.azure_cloud.eql?("AzureChinaCloud") || adapter.csp_adapter? || adapter.ea_adapter?)
      adapter.subscription.reload_rate_cards unless Azure::RateCard.where(subscription_id: adapter.subscription_id).exists?
      adapter.subscription.reload_usage_cost if adapter.subscription.usage_cost_reload_require?
    end
    
    resource_types = Synchronizers::Azure::SYNC_RESOURCES.collect { |klass| klass.constantize::AZURE_RESOURCE_TYPE }.reject(&:blank?)

    callback_params = {
      bid: batch.bid,
      adapter_id: adapter.id,
      account_id: adapter.account_id,
      region_ids: enabled_region_map.values,
      synchronization_id: synchronization_id,
      resource_group_names: adapter.resource_groups.active.pluck(:name),
      queue_name: queue_name
    }

    batch_description = "Batch to fetch azure resources for adapter_id : #{adapter.id}, adapter name : #{adapter.name}"

    exec_batch = proc {
      adapter.resource_groups.active.find_in_batches(batch_size: 100).each do |batch|
        CSLogger.info "processing batch of - #{batch.count}"
        batch.each do |resource_group|
          res = adapter.azure_resources.list_by_resource_group(resource_group.name, {resource_type: resource_types})
          res.on_success do |azure_resources|
            if azure_resources.blank?
              Azure::Resource.where(azure_resource_group_id: resource_group.id).update_all(state: :deleted)
              next
            end
            # on_success method yields different type of response depending on below scenario..
            # if adapter.azure_resources.list_by_resource_group calling SDK then it will return array of 'Azure::Resources::Mgmt::V2020_06_01::Models::GenericResourceExpanded'
            # if adapter.azure_resources.list_by_resource_group calling REST api then it will return array of hash.
            # so we are trying both to fetch resource_type
            available_resource_types = azure_resources.map { |resource| resource.try(:type) || resource.try(:[], 'type') }
            callback_params.merge!({resource_group_name: resource_group.name, resource_group_id: resource_group.id, enabled_region_ids: enabled_region_map.values})
            rg_batch = Sidekiq::BatchCreator.call(Azure::DataManager::ResourceFetcherCallback, callback_params, batch_description)
            rg_batch.jobs do
              Synchronizers::Azure::SYNC_RESOURCES.each do |klass|
                unless available_resource_types.include?(klass.constantize::AZURE_RESOURCE_TYPE)
                  klass.constantize.where(azure_resource_group_id: resource_group.id).update_all(state: :deleted)
                  if Synchronizers::Azure::CHILD_RESOURCES.keys.include?(klass)
                    Synchronizers::Azure::CHILD_RESOURCES[klass].each do |child_klass|
                      child_klass.constantize.where(azure_resource_group_id: resource_group.id).update_all(state: :deleted)
                    end
                  end
                  next
                end
                if queue_name.present?
                  Sync::Azure::Resource::FetcherWorker.set(queue: queue_name).perform_async(klass, adapter_id, resource_group.id, enabled_region_map)
                else
                  Sync::Azure::Resource::FetcherWorker.perform_async(klass, adapter_id, resource_group.id, enabled_region_map)
                end
              end
            end
          end
          res.on_error do |error_code, error_message, data|
            CSLogger.error "resource fetch error code; #{error_code}, message: #{error_message}"
          end
        end
      end
    }

    Sidekiq::Batch.new(batch.bid).jobs(&exec_batch)

  rescue StandardError => e
    CSLogger.error e.message
    CSLogger.error e.backtrace
  end

end
