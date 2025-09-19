# frozen_string_literal: false

# worker for service auto ignore
class UnIgnoreServiceWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, retry: false, backtrace: true

  def perform(_service_id, service_detail_id, acccount_id, tenant_id)
    CSLogger.info 'Service auto un-ignoring started...'
    begin
      service_detail = ServiceDetail.find service_detail_id
      user = User.find_by(username: service_detail.commented_by)
      account = Account.find acccount_id
      tenant = Tenant.find tenant_id
      filters = {
        adapter_id: service_detail.adapter_id,
        region_id: service_detail.region_id,
        provider_type: service_detail.provider_type,
        provider_id: service_detail.provider_id,
        comment: 'Auto un-ignored',
        comment_type: 'un-ignored',
        user_id: user&.id
      }
      ServiceAdviser::Base.unignore_service(filters, account, tenant)
    rescue StandardError => e
      CSLogger.error e.message
      CSLogger.error e.backtrace
    end
  end
end
