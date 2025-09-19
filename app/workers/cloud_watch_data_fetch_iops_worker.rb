class CloudWatchDataFetchIopsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :idle_service_queue, :retry => false, backtrace: true

  def perform(options)
    CSLogger.info "---- Started Fetching Cloudwatch Data For Recommandation iops account id - #{options['account_id']} ----"
    adapter_ids = options['adapter_ids']
    account_region_ids = options['account_region_ids']
    account_id = options['account_id']

    aws_account_ids_with_adapters = Adapters::AWS.active_adapters.normal_adapters.where(id: adapter_ids).group_by(&:aws_account_id)
    return if aws_account_ids_with_adapters.empty?

    # Deleting the data with both filters aws account id & adapter id
    MatricMaxUsageStorage.where(:adapter_id.in => aws_account_ids_with_adapters.values.flatten.map(&:id)).delete_all

    callback_options = { 'adapter_id' => aws_account_ids_with_adapters.values.flatten.map(&:id), 'account_id' => account_id }
    parent_batch = Sidekiq::Batch.new(batch.bid)
    parent_batch.jobs do
      child_batch = Sidekiq::BatchCreator.call(AWSDailyIdleService::IOPS::AdapterWiseCallback, callback_options, "CloudWatchDataFetchIopsWorker for Account with Adapter Wise - #{account_id}")
      child_batch.jobs do
        aws_account_ids_with_adapters.each do |aws_account_id, adapters|
          # Here we are considering each account has single adapter with releated to aws account ids
          # Thats Why we are removing old code i.e break statment here
          adapter = adapters.first
          account_region_ids.each do |region_id|
            worker_options = Hash.new
            worker_options['adapter_id'] = adapter.id
            worker_options['region_id'] = region_id
            worker_options['account_id'] = account_id

            CloudWatchDataFetchIopsAdapterRegionWorker.perform_async(worker_options)
          end
        end
      end
    end
    CSLogger.info "---- Completed Fetching Cloudwatch Data For Recommandation iops account id - #{options['account_id']} ----"
  rescue Exception => e
    CSLogger.error "==== oh No Exception in CloudWatchDataFetchIopsWorker for account id - #{options['account_id']} | Error Message - #{e.message} ==========="
    CSLogger.error e.backtrace
    raise e
  end
end
