class CreateLinkAdaptersWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, :retry => false

  # Note: This is also use for gcp
  def perform(adapter_id,params,aws_accounts,organisation_id,user_id,tenant_id=nil)
    CSLogger.info "=========================In CreateLinkAdaptersWorker=#{adapter_id}============"
    adapter = Adapter.find_by_id(adapter_id)
    organisation = Organisation.find_by_id(organisation_id)
    user = User.find_by_id(user_id)
    tenant = tenant_id.nil? ? nil : Tenant.find_by_id(tenant_id)
    unless adapter.nil?
      begin
       adapter.create_new_iam_adapter(params, aws_accounts, organisation, user, tenant)
      rescue StandardError => e
        CSLogger.error "CreateLinkAdaptersWorker | Error: #{e.message} | params: #{params} | adapter_id: #{adapter_id}}"
      end
    end
  end
end
