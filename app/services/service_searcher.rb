class ServiceSearcher < CloudStreetService
  def self.search(account_id, &block)
    #account = Account.find(account_id)
    #services = account.services.monitored
    services = Service.includes(interfaces: [:connections]).where(account_id: account_id).load

    yield Status.success(services)
    return
  end

  def self.find(service, &block)
    service = fetch Service, service

    yield Status.success(service)
  end
end
