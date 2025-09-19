class ServiceUpdaterAsync < CloudStreetServiceAsync

  def perform(service, user)
    ServiceUpdater.execute(service, user)
  end

  def self.execute(service, user, &block)
    # Have to pull service out again as the block code will expect it
    service = fetch Service, service

    ServiceUpdaterAsync.perform_async(service.id, user)
    status ServiceStatus, :success, service, &block
  end
end
