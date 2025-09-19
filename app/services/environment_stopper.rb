class EnvironmentStopper < CloudStreetService

  def self.stop!(environment, user, &block)
    stop(environment, user, EnvironmentStopperAsync, &block)
  end

  def self.stop(environment, user, stopper=EnvironmentStopper, &block)
    environment = fetch Environment, environment
    user        = fetch User, user

    if !environment.default_adapter.active?
      if !environment.default_adapter.verify_connections?
        status EnvironmentStatus, :invalid_adapter, environment, &block
        return environment
      else
        environment.default_adapter.activate!
      end
    end

    if environment.stopping?
      status EnvironmentStatus, :already_stopping, environment, &block
      return environment
    end

    if environment.stopped?
      status EnvironmentStatus, :already_stopped,  environment, &block
      return environment
    end

    if environment.can_stop?
      environment.desired_state = "stopped"
      environment.updated_by = user.id
      environment.save!
      environment.stop!
      stopper.execute(environment.id, user.id, &block)
    else
      CSLogger.error "Unable to stop environment from current state"
      status EnvironmentStatus, :invalid_state, environment, &block
    end

    return environment
  end

  def self.execute(environment, user, &block)
    environment = fetch Environment, environment
    user        = fetch User, user

    if EnvironmentStoppable.stop(environment, user)
      revision_data = { services_data: {}, changed_services: [], connections: {}, number: ('%.2f'%environment.revision) }
      Events::Environment::Shutdown.create(account: environment.account, environment: environment, user: user, revision_data: revision_data)      
      status EnvironmentStatus, :success, environment, &block
    else
      CSLogger.error "Error running EnvironmentStoppable.stop(#{environment.id})"
      status EnvironmentStatus, :error, environment, &block
    end
  end
end
