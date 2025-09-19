class SubnetFetchWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api, retry: false, backtrace: true

  def perform(provider_id, autoscaling_id)
    # environment = Environment.find environment_id
    service = Service.find autoscaling_id
    Services::Network::Subnet::AWS.fetch_remote_subnet(provider_id, service)
  rescue => exception
    CSLogger.error "#{exception.backtrace}"
    raise exception
  end
end
