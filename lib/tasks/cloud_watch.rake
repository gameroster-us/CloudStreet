namespace :cloud_watch do
  desc "Fetch the latest cloud watch services"
  task fetch_cloud_watch_data_iops: :environment do
    # CloudWatchDataFetchWorker.perform_async

    account_id, adapters = Adapters::AWS.active_adapters.normal_adapters.for_active_accounts.group_by(&:account_id).first
    exit unless account_id.present?

    adapters.select!{ |adapter| adapter.verify_connections? }
    account_region_ids = account_region_ids = Account.find(account_id)&.regions&.aws&.ids

    callback_options = {}
    callback_options['account_id'] = [account_id]
    callback_options['current_account_id'] = account_id

    unless account_region_ids.any? && adapters.any?
      # Directly calling callback as no condition is met in the above condition
      callback_options['current_adapter_ids'] = []
      CSLogger.info "----- Initiating and Skipping CloudWatchDataFetchIopsWorker for | Account ID - #{callback_options["current_account_id"]} -----"
      AWSDailyIdleService::IOPS::AccountWiseCallback.new.on_complete(true, callback_options)
      exit
    end

    worker_options = {}
    worker_options['account_id'] = account_id
    callback_options['current_adapter_ids'] = worker_options['adapter_ids'] = adapters.map(&:id)
    worker_options['account_region_ids'] = account_region_ids

    CSLogger.info "----- Initiating CloudWatchDataFetchIopsWorker for | Account ID - #{callback_options["current_account_id"]} -----"
    account_batch = Sidekiq::BatchCreator.call(AWSDailyIdleService::IOPS::AccountWiseCallback, callback_options, "CloudWatchDataFetchIopsWorker for Account- #{account_id}")
    account_batch.jobs do
      CloudWatchDataFetchIopsWorker.perform_async(worker_options)
    end
  end
end

