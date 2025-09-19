class SecurityScanIamRoleFetchWorker
  include Sidekiq::Worker
  sidekiq_options queue: :security_scan_data, retry: false, backtrace: true
  def perform
    IamRoleDetailsFetcher.get_uniq_account_iam_role_data
  end
end
