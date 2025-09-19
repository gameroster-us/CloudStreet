class SecurityScanPolicyFetchWorker
  include Sidekiq::Worker
  sidekiq_options queue: :security_scan_data, retry: false, backtrace: true
  def perform
    IamPolicyFetcher.get_uniq_account_iam_policy_data
  end
end
