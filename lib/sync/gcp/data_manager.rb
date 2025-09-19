require './lib/node_manager.rb'
class GCP::DataManager
  extend Sync::BaseSyncWorker
  include Sync::GCP::Callbacks

  def initialize(options)
    CSLogger.info "Step 2 GCP Starting Synchronization | acc_id- #{options['account_id']} | adp_ids - #{options['adapter_ids']} | bg jobs - #{options['back_ground_job']}"
    @account = Account.find(options['account_id'])
    @back_ground_job = options['back_ground_job']
    @queue_name = options['queue_name']
    @parent_batch = Sidekiq::Batch.new(options['batch_id']) if options['batch_id'].present?
    @adapters = Adapters::GCP.get_active_adapters_for_sync(options['adapter_ids']).compact
    CSLogger.info "Step 2 again GCP Synchronization active | adp_ids - #{options['adapter_ids']} | adp_names - #{@adapters.pluck(:name).join(',')}"
    @adapters.each do |adapter|
      adapter.update_attribute(:sync_running, true)
    end
    unless @adapters.empty?
      # In case of auto sync multiple active adapter comes here but
      # (continue) if some adapter are not valid, so do not send them to log_sync_start its fixed now.
      CSLogger.info "Step 2 again again GCP Synchronization active #{@adapters.pluck(:id)}"
      options["adapter_ids"] = @adapters.pluck(:id)
      @synchronization = @account.log_sync_start(options)
      params = {
        auto_sync_to_cs_from_aws: @synchronization.auto_sync_to_cs_from_aws,
        account_id: @account.id,
        synchronization_id: @synchronization.id,
        back_ground_job: @back_ground_job,
        queue_name: @queue_name
      }
      @main_sync_batch = Sidekiq::BatchCreator.call(GCP::DataManager::MainSyncCallback, params, 'GCP main sync batch for adapters')
    end
  end

  def exec_sync
    return unless @main_sync_batch.present?

    if @parent_batch.present?
      @parent_batch.jobs do
        @main_sync_batch.jobs do
          Sync::GCP::MainSyncWorker.set(queue: @queue_name).perform_async(@adapters.map(&:id), @account.id, @synchronization.id, @queue_name)
        end
      end
    else
      @main_sync_batch.jobs do
        Sync::GCP::MainSyncWorker.perform_async(@adapters.map(&:id), @account.id, @synchronization.id)
      end
    end
  end

  class << self
    def schedule_adapter_sync(adapter_ids, account_id, synchronization_id, batch_id, queue_name)
      CSLogger.info "Step 4 GCP multiple adapters | adp_ids - #{adapter_ids}"
      account = Account.find(account_id)
      adapters = Adapters::GCP.get_active_adapters_for_sync(adapter_ids).compact
      synchronization = Synchronization.find(synchronization_id)
      synchronizer = ServiceSynchronizer.new(account.id)
      synchronizer.sync_progress_start(adapters)
      enabled_region_map = Hash[Region.get_enabled_regions(account.id, :gcp).pluck(:code, :id)]

      Sidekiq::Batch.new(batch_id).jobs do
        adapters.each do |adapter|
          synchronizer.start_sync!(adapter.id)
          wrapper(account.id, adapter.id) {
            begin
              callback_params = {
                batch_id: batch_id,
                adapter_id: adapter.id,
                account_id: adapter.account_id,
                region_ids: enabled_region_map.values,
                synchronization_id: synchronization.id,
                queue_name: queue_name
              }
              batch_description = "Batch to fetch GCP resources for adapter_id : #{adapter.id}, adapter name : #{adapter.name}"
              adapter_batch = Sidekiq::BatchCreator.call(GCP::DataManager::AdapterSyncCallback, callback_params, batch_description)
              adapter_batch.jobs do
                if queue_name.present?
                  Sync::GCP::AdapterSynchronizerWorker.set(queue: queue_name).perform_async(adapter.id, synchronization.id, queue_name)
                  Sync::GCP::AdapterGlobalSynchroniserWorker.set(queue: queue_name).perform_async(adapter.id)
                else
                  Sync::GCP::AdapterSynchronizerWorker.perform_async(adapter.id, synchronization.id)
                  Sync::GCP::AdapterGlobalSynchroniserWorker.perform_async(adapter.id)
                end
              end
            rescue StandardError => e
              @failed = true
              CSLogger.error "ISSUE HERE Step 4 schedule_adapter_sync | Error - #{e.message} | adp_ids - #{options['adapter_id']}"
              CSLogger.error "#{e.class} : #{e.message} : #{e.backtrace}"
              adapter.update(sync_running: false)
              synchronization.mark_adapter_wise_sync_status_gcp(adapter.id, Synchronization::FAILED)
            end
          }
        end
      end
    end
  end
end
