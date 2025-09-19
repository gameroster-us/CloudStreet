class EnvironmentParentServices < CloudStreetService
  
  PARENT_SERVICES = %w(Services::Vpc Services::Database::Rds Services::Compute::Server Services::Network::RouteTable Services::Network::SecurityGroup)
    
  def self.get_parent_services(account_id, id, &block)
  	account = Account.find(account_id)
    environment = account.environments.find(id)

    parent_services = environment.services.select{ |service| PARENT_SERVICES.include?(service.generic_type) }

    status Status, :success, parent_services, &block
    return parent_services
  end
end
