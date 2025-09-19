class ReloadServices::FetchAdditionalDataWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, retry: true, backtrace: true

  def perform(service_type, service_id, reload_env_hash_names)
    CSLogger.info "Environment Reload: Started fetching additional data for #{service_id} of type #{service_type}"
    EnvironmentReloader.fetch_and_save_additional_data_in_redis(service_type, service_id, reload_env_hash_names)
    CSLogger.info "Environment Reload: Finished fetching additional data for #{service_id} of type #{service_type}"
  rescue => exception
    CSLogger.error "#{exception.class} #{exception.message} #{exception.backtrace}"
    raise exception
  end
end