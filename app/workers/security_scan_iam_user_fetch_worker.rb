class SecurityScanIamUserFetchWorker
  include Sidekiq::Worker
  sidekiq_options queue: :security_scan_data, retry: false, backtrace: true
  def perform
    IamDetailsFeatcherService.get_uniq_account_iam_data
  end

end
