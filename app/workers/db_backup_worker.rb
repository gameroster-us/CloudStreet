class DBBackupWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, retry: false, backtrace: true

  def perform(*args)
    CSLogger.info "Started export data to s3"
    DBBackupService.export_data_to_s3
    CSLogger.info "Finished export data to s3"
  rescue StandardError => exception
    CSLogger.error "#{exception.class} #{exception.message} #{exception.backtrace}"
    raise exception
  end
end
