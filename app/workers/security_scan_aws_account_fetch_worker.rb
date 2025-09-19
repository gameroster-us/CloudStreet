class SecurityScanAWSAccountFetchWorker
  include Sidekiq::Worker
  sidekiq_options queue: :security_scan_data, retry: false, backtrace: true
  def perform
    AWSAccountDetailsFetcher.get_uniq_account_details
  end

end
