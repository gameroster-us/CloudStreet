namespace :ami do
  desc "Fetching AMI's from all providers"
  task fetch: :environment do
    CSLogger.info "Started Fetching AMI's"
    ActiveRecord::Base.connection_pool.with_connection do
      MachineImageFetcher.fetch_amis_for_providers
    end
  end

  desc "Fetching AMI's for all providers sequentially"
  task sequentialy_fetch: :environment do
    CSLogger.info "Started Fetching AMI's sequentially"
    ActiveRecord::Base.connection_pool.with_connection do
      SequentialAmiFetcherWorker.perform_async
    end
  end
end
