class EnvironmentProvisioner < CloudStreetService
  def self.provision(environment, user, &block)
    environment = fetch Environment, environment
    user        = fetch User, user

    CSLogger.info "EnvironmentProvisioner.provision(environment: #{environment.id}, user: #{user.id})"

    if !environment.default_adapter
      CSLogger.info "No default adapter for environment!"
      status EnvironmentProvisionStatus, :no_default_adapter, environment, &block
      return environment
    end

    if environment.running?
      CSLogger.info "Environment already running!"
      status EnvironmentProvisionStatus, :already_running, environment, &block
      return environment
    end

    environment.desired_state = "running"
    environment.save!

    EnvironmentProvisionable.new(environment).provision_order.each do |service|
      service.adapter = environment.default_adapter
      service.save!

      CSLogger.info "* Configuring #{service.type} (#{service.id})"
      CSLogger.info "  Sending event `service_pre-install`"

      ServiceProvisioner.provision(service.id, user.id) do |result|
        result.on_success { |service| CSLogger.info "OMGOMGOMG success: #{service.inspect}" }
        result.on_error   { |error|   CSLogger.error "OMGOMGOMG error: #{error.inspect}" }
      end
    end

    Events::Environment::Provision.create!(environment: environment, user: user)
    # Engine::Metrics.increment "CloudStreet.engine.environment.provision"

    status EnvironmentProvisionStatus, :provisioning, environment, &block
    return environment
  end
end
