class SecurityScanners::ApplicationScanWorker
	include Sidekiq::Worker
  sidekiq_options queue: :api, retry: false, backtrace: true

  def perform(account_id)
    begin
      SecurityScanner.start_application_scan(account_id)
    rescue Exception => e
      CSLogger.error "#{e.class} Exception"
      CSLogger.error e.message
      CSLogger.error e.backtrace
    end
  end
end