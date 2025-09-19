class Sync::Azure::MainSyncWorker
  include Sidekiq::Worker
  sidekiq_options queue: :azure_sync, backtrace: true

  def perform(adapter_ids, account_id, synchronization_id, queue_name = nil)
    Azure::DataManager.schedule_adapter_sync(adapter_ids, account_id, synchronization_id, batch.bid, queue_name)
  end

end
