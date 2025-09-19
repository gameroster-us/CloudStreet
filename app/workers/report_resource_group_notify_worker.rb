class ReportResourceGroupNotifyWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, :retry => false, backtrace: true

  def perform(options ={})
  CSLogger.info '================In ReportResourceGroupNotifyWorker============='
    organisation = Organisation.find_by_id(options[:organisation_id])
    user = User.find_by_id(options[:user_id])
    url = "#{Settings.report_host}/api/v1/report_dashboards/tenant_resource_group_update"
    RestClientService.post(url, user, {subdomain: organisation.subdomain, tenant_id: options["tenant_id"]})
  end
end