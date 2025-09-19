require "./lib/node_manager.rb"
class DataStoreManager
  attr_accessor :adapters, :synchronization

  def initialize(options)
    CSLogger.info("starting synchronization with #{options}")
    ActiveRecord::Base.transaction do
      @adapters = Adapters::AWS.get_active_ids_for_sync(options["adapter_ids"], options["account_id"])
      options['adapter_ids'] = @adapters.pluck(:id)
      # Update sync running status as true.
      # this is applicable for auto sync only.
      # for normal sync the adapters' sync staus already updated
      # from `ServiceSynchronizerAsync`
      @adapters.each do |adapter|
        next if adapter.sync_running

        adapter.update(sync_running: true)
      end
      unless @adapters.empty?
        @region_ids = options["region_ids"]
        @account = Account.find(options["account_id"]) # find account using account id instead of user id for multi tenant implementation 
        @synchronization = @account.log_sync_start(options)
        @parent_batch = Sidekiq::Batch.new(options["batch_id"]) if options["batch_id"].present?
        @batch = Sidekiq::Batch.new
        @batch.description = "Main Sync Batch for adapters"
        @queue_name = options['queue_name']
        params = {
          auto_sync_to_cs_from_aws: true,
          account_id:         @account.id,
          synchronization_id: @synchronization.id,
          queue_name:         @queue_name,
          batch_id:           options["batch_id"] || @batch.bid
        }
        @batch.on(:complete, Sync::Callbacks::MainSyncCallback, params)
        @batch.on(:success, Sync::Callbacks::MainSyncCallback, params)
      end
    end
  rescue Exception => e
    CSLogger.error("DataStoreManager initialize--- #{e.class} #{e.message} #{e.backtrace}")
    Sync::Callbacks.notify_sync_failed(@synchronization.id, options["adapter_ids"], options["account_id"])
  end



  def exec_sync
    return unless @batch.present?
    regions = @region_ids.blank? ? @account.get_sync_enabled_aws_regions_ids : Region.aws.where(id: @region_ids).pluck(:id, :code)
    template_costs = TemplateCosts::AWS.where(region_id: regions.map(&:first))
    sync_regions = regions.select do |region|
      region_id, region_code = region
      template_cost = template_costs.find{|tcost| tcost.region_id.eql?(region_id)} rescue nil
      ::REDIS.with do |conn|
        cost_data = (template_cost.data[region_code] rescue {})
        conn.set("#{region_code}_cost", cost_data.to_json)
      end
      true
    end
    adapters_data = @adapters.collect do |adapter|
      #This 3 worker are not linked with batch bcuz it take time to execute.
      SecurityScanSyncWorker.perform_async(adapter.id)
      EncryptionKeysFetchWorker.perform_async(adapter.id)
      StorageSynchroniserWorker.perform_async(adapter.id)
      {
        id: adapter.id,
        name: adapter.name,
        sync_state: Synchronization::RUNNING,
        total_count: 100,
        pending: 100,
        completed_count: 0,
        phase: 1
      }
    end
    ::NodeManager.send_sync_progress(@account.id, adapters_data)
    if @parent_batch.present?
      @parent_batch.jobs do
        @batch.jobs do
          if @queue_name.present?
            Sync::MainSyncWorker.set(queue: @queue_name).perform_async(@adapters.map(&:id), @account.id, sync_regions, @synchronization.id, @queue_name)
          else
            Sync::MainSyncWorker.perform_async(@adapters.map(&:id), @account.id, sync_regions, @synchronization.id)
          end
        end
      end
    else
      @batch.jobs do
        if @queue_name.present?
          Sync::MainSyncWorker.set(queue: @queue_name).perform_async(@adapters.map(&:id), @account.id, sync_regions, @synchronization.id, @queue_name)
        else
          Sync::MainSyncWorker.perform_async(@adapters.map(&:id), @account.id, sync_regions, @synchronization.id)
        end
      end
    end
  end

  module Utf8Converter
    def self.convert_to_utf_8(object)
      if object.is_a?(String)
        object.force_encoding("UTF-8")
      elsif object.is_a?(Hash)
        object.keys.each do|key|
          object[key]=convert_to_utf_8(object[key])
        end
      else
        object
      end
      object
    end
  end

  class AutoSyncCallback
    def on_complete(status, options)
      if status.failures != 0
        pp "AutoSyncCallback Uh oh, batch has failures"
      else
        pp "AutoSyncCallback Processed workers"
        sync = Synchronization.find(options['synchronization_id'])
        unless sync.adapter_ids.blank?
          sync.adapter_ids.each do |adapter_id|
            SecurityScanner.start_adapter_scan!(adapter_id, sync.region_ids)
          end
        end
      end
    end

    def on_success(status, options)
      CSLogger.info("auto sync success callback")
      UpdateUnusedElbsWorker.perform_async
      adapter = Adapter.find(options["adapter_id"])
      adapter.update(sync_running: false) if adapter
      ::NodeManager.send_sync_progress(options["account_id"], [{
                                                                 id: options["adapter_id"],
                                                                 sync_state: Synchronization::SUCCESS,
                                                                 total_count: 100,
                                                                 pending: 0,
                                                                 completed_count: 100
      }])
      synchronization = Synchronization.find(options["synchronization_id"])
      synchronization.mark_adapter_wise_sync_status_for_aws(options["adapter_id"], Synchronization::SUCCESS)
      # bulk index into solr start-
      filter = { adapter_id: options["adapter_id"] }
      SolrOperations::IndexObjectsIntoSolrWorker.perform_async("Service", Service.where(filter).synced_services.map(&:id), "filter- #{filter}")
      SolrOperations::IndexObjectsIntoSolrWorker.perform_async("Snapshot", Snapshot.where(filter).map(&:id), "filter- #{filter}") # bulk index into solr
      # - bulk index into solr end
      CSLogger.info("auto sync success callback end")
    end
  end

  # class ScheduleSyncCallback
  #   def on_complete(status, options)
  #     if status.failures != 0
  #       Sidekiq.logger.warn "ScheduleSyncCallback Uh oh, batch has failures"
  #     else
  #       Sidekiq.logger.warn "ScheduleSyncCallback Processed workers"
  #       sync = Synchronization.find(options['synchronization_id'])
  #       unless sync.adapter_ids.blank?
  #         sync.adapter_ids.each do |adapter_id|
  #           SecurityScanner.start_adapter_scan!(adapter_id, sync.region_ids)
  #         end
  #       end
  #     end
  #   end

  #   def on_success(status, options)
  #     CSLogger.info("scheudle sync success callback")
  #   end
  # end

  def self.schedule_adapter_sync(adapter_ids, account_id, sync_regions, synchronization_id, batch_id, queue_name = nil)
    adapters = Adapter.where(id: adapter_ids)
    synchronization = Synchronization.find(synchronization_id)
    Sidekiq::Batch.new(batch_id).jobs do
      adapters.each do |adapter|
        region_codes = sync_regions.map(&:last)
        adapter_enabled_regions_query = Region.where(code: region_codes).where.not(code: adapter.not_supported_regions)
        adapter_enabled_regions = adapter_enabled_regions_query.pluck(:id, :code)
        adapter_batch = Sidekiq::Batch.new
        adapter_batch.description = "Batch to fetch data from AWS for adapter #{adapter.name}"
        params = {
          auto_sync_to_cs_from_aws: true,
          synchronization_id: synchronization.id,
          account_id:         synchronization.account_id,
          adapter_id:         adapter.id,
          region_ids:         adapter_enabled_regions_query.pluck(:id),
          queue_name:         queue_name,
          parent_bid:         batch_id
        }
        adapter_batch.on(:complete, Sync::Callbacks::AdapterSyncCallback, params)
        adapter_batch.on(:success, Sync::Callbacks::AdapterSyncCallback, params)
        ::REDIS.with do |conn|
          conn.set(adapter.redis_key_holder, adapter.attributes.to_json)
        end
        synchronization.service_sync_status[adapter.id] = {}
        synchronization.save
        adapter_batch.jobs do
          if queue_name.present?
            Sync::AdapterSyncWorker.set(queue: queue_name).perform_async(adapter.id, account_id, adapter_enabled_regions, synchronization_id, queue_name)
          else
            Sync::AdapterSyncWorker.perform_async(adapter.id, account_id, adapter_enabled_regions, synchronization_id)
          end
        end
      end
    end
  end

  def self.schedule_remote_service_fetcher(adapter_id, account_id, sync_regions, synchronization_id, batch_id, queue_name = nil)
    adapter = Adapter.find(adapter_id)
    synchronization = Synchronization.find(synchronization_id)
    begin
      adapter.reset_provider_data_store(sync_regions.map(&:first), queue_name)
      Sidekiq::Batch.new(batch_id).jobs do
        service_fetcher_batch = Sidekiq::Batch.new
        service_fetcher_batch.description = "Batch to fetch remote service from AWS for adapter #{adapter.name}"
        params = {
          auto_sync_to_cs_from_aws: true,
          synchronization_id: synchronization.id,
          account_id:         synchronization.account_id,
          adapter_id:         adapter.id,
          region_ids:         synchronization.region_ids,
          queue_name:         queue_name
        }
        service_fetcher_batch.on(:complete, Sync::Callbacks::FetcherSyncCallback, params)
        service_fetcher_batch.on(:success, Sync::Callbacks::FetcherSyncCallback, params)

        service_fetcher_batch.jobs do
          sync_regions.each do |region|
            region_id , region_code = region
            AWSRecord::SYNC_SERVICES_MAP.each do |service_klass|
              options = {
                region_code: region_code,
                adapter_id: adapter.id,
                adapter_name: adapter.name,
                region_id: region_id,
                account_id: account_id,
                synchronization_id: synchronization.id,
                auto_sync_to_cs_from_aws: true,
                klass:  AWSRecord.get_service_type(service_klass),
                queue_name: queue_name
              }
              if queue_name.present?
                Sync::FetchRemoteServicesWorker.set(queue: queue_name).perform_async(options)
              else
                Sync::FetchRemoteServicesWorker.perform_async(options)
              end
            end
          end
        end
      end
    rescue RSolr::Error::ConnectionRefused, Exception => e
      CSLogger.error("====== Error : #{e.message} ======")
      CSLogger.error(e.backtrace)
      adapter.update(sync_running: false)
      ::NodeManager.send_sync_progress(
        account_id, [{
                               id: adapter.id,
                               sync_state: Synchronization::FAILED,
                               error_message: "failure 1"
                             }
                             ])
      unless e.is_a?(RSolr::Error::ConnectionRefused)
        if synchronization.present?
          synchronization.mark_adapter_wise_sync_status_for_aws(adapter.id, Synchronization::FAILED)
          synchronization.force_teminate!
        end
      end
    end
  end

end
