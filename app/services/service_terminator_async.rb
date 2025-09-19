class ServiceTerminatorAsync < CloudStreetServiceAsync
  def self.execute(service, user, is_onlyservice, params, &block)
    ::ServiceActionsWorker.perform_async(ServiceTerminator, service.id, user.id, is_onlyservice, params)
    status ServiceStatus, :success, service, &block
  end
end
