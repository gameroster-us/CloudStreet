class SecurityScanners::AdapterScanWorker
	include Sidekiq::Worker
  sidekiq_options queue: :api, retry: false, backtrace: true

  def perform(adapter_id,region_ids, notify)
    begin
      SecurityScanner.start_adapter_scan(adapter_id, region_ids, notify)
    rescue Exception => e
      CSLogger.error "#{e.class} Exception"
      CSLogger.error e.message
      CSLogger.error e.backtrace
    end
  end
end