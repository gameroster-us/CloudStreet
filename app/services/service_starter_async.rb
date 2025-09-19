require_relative '../../lib/cloudstreet/service_sidekiq_callback'
class ServiceStarterAsync < CloudStreetServiceAsync
  def self.execute(service, user, is_onlyservice, params, class_name=nil, &block)
    class_name = "ServiceSidekiqCallback" if class_name.blank?
    call_back_batch = Sidekiq::Batch.new
    options = { environment_id: service.try(:environment).try(:id), user_id: user.id }
    call_back_batch.on(:success, "CloudStreet::#{class_name}".constantize, options)
    call_back_batch.jobs do
      if service.environment.nil?
        ::ServiceActionsWorker.perform_async(Service::AWS::Starter, service.id, user.id, is_onlyservice, params)
      else
        ::ServiceActionsWorker.perform_async(ServiceStarter, service.id, user.id, is_onlyservice, params)
      end
    end
    status ServiceStatus, :success, service, &block
  end
end
