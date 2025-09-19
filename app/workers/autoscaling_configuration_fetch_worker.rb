class AutoscalingConfigurationFetchWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, retry: false, backtrace: true
  def perform(provider_id, autoscaling_id)
    service = Service.find autoscaling_id
    Services::Network::AutoScalingConfiguration::AWS.fetch_remote_lc(provider_id, service)
    CSLogger.info "Successfully ran server fetcher via sidekiq"
  rescue => exception
    CSLogger.error "#{exception.backtrace}"
    raise exception
  end
end
