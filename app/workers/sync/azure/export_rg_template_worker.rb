require "./lib/node_manager.rb"
class Sync::Azure::ExportRgTemplateWorker
  include Sidekiq::Worker
  include Sync::BaseSyncWorker
  sidekiq_options queue: :api, :retry => false, backtrace: true
  def perform(options)
    CSLogger.logger.tagged("ExportRgTemplate adapter:#{options['adapter_name']}, rg:#{options['name']}") do 
      sync_redis_hash_name = "syncAzureAdapter:#{options['adapter_id']}"
      wrapper(options['account_id'], options['adapter_id']){|synchronizer|
        adapter_str = ""
        account_enabled_regions_str = ""
        ::REDIS.with do |conn|
          adapter_str = conn.hget(sync_redis_hash_name, "adapter")
          account_enabled_regions_str = conn.hget(sync_redis_hash_name, "account_enabled_regions")
         end
        adapter = Adapter.new JSON.parse(adapter_str)
        begin
          ActiveRecord::Base.transaction do
            exported_template = Azure::Resource::ResourceGroup.export_template(adapter, options["provider_subscription_id"], options['name'])
            synchronizer.send_progress(Sidekiq::Batch::Status.new(options["batch_id"]), adapter, 3)
            if exported_template.present?
              account_enabled_regions = JSON.parse(account_enabled_regions_str)
              rg_attributes = options.except('provider_subscription_id', 'azure_klass', 'batch_id','synchronization_id', 'adapter_name')
              resource_group = Azure::Resource::ResourceGroup.new(rg_attributes)
              CSLogger.info "Started processing the RG template"
              resource_group.process_exported_template(exported_template, account_enabled_regions, options)
              CSLogger.info "Started processing the RG template"
            end
          end
        rescue Exception => e
          @failed = true
          adapter = Adapter.find_by_id(options["adapter_id"])
          CSLogger.error("Error occured in ExportRgTemplateWorker #{e.class} : #{e.message} : #{e.backtrace}")
          adapter.update_attribute(:sync_running, false)
          ::REDIS.with do |conn|
            conn.del(sync_redis_hash_name)
          end
          synchronization = Synchronization.find_by_id(options['synchronization_id'])
          if synchronization.present?
            synchronization.mark_adapter_wise_sync_status(options["adapter_id"], Synchronization::FAILED)
            synchronization.force_teminate!
          end
          synchronizer.failed(options["adapter_id"])
          raise e
        end
      }
    end
  end
end