class ServiceStopper < CloudStreetService
  
  def self.stop!(service, user, &block)
    if service.environment.nil?
      user = fetch User, user
      ServiceStopperAsync.execute(service, user, true, {}, &block)
    else
      stop(service, user, ServiceStopperAsync, &block)
    end
  end

  def self.stop(service, user, stopper=ServiceStopper, &block)
    service     = fetch Service, service
    user        = fetch User, user

    if service.is_autoscaling?
      service.suspend_autoscaling
    end

    if !service.adapter.active?
      status ServiceStatus, :inactive_adapter, service, &block
      return service
    end

    if service.stopping?
      CSLogger.info "Service already stopping"
      status ServiceStatus, :already_stopping, service, &block
      return service
    end

    if service.stopped?
      CSLogger.info "Service already stopped"
      status ServiceStatus, :already_stopped, service, &block
      return service
    end

    if !service.support_stop?
      CSLogger.info "Service does not support stop operation"
      status ServiceStatus, :not_supported, I18n.t('errors.services.stopping.not_supported'), &block
      return service
    end

    if service.can_stop?
      if stopper == ServiceStopperAsync
        stopper.execute(service, user, true, {}, &block)
      else
        stopper.execute(service, user, false, {}, &block)
      end
    else
      CSLogger.error "Unable to transition service from current #{service.state} to stopped"
      status ServiceStatus, :invalid_state, service, &block
    end

    return service
  end

  def self.execute(service, user, is_onlyservice, params, &block)
    service     = fetch Service, service
    user        = fetch User, user
    environment = service.environment

    CSLogger.error "Stopping service #{service.id} (#{service.name}/#{service.type})"
    Pusher[service.id].trigger("deploy_event", "service_stopping")

    # ServiceEventable.send_event(service, :connection_down)
    ServiceEventable.send_event(service, :stop)

    environment = service.environment
    environment.update_attribute :updated_by, user.id

    if ServiceStoppable.stop(service)

      # Events::Service::Shutdown.create(account: service.account, service: service, user: user, environment: environment, revision: environment.revision)
      revision_data = environment.prepare_revision_data(event: 'stopped', service: service)      
      Events::Service::Shutdown.create(account: service.account, service: service, environment: environment, user: user, revision_data: revision_data)
  
      Pusher[service.id].trigger("deploy_event", "service_stopped")
      ::ImageUpdateWorker.perform_async(environment.id, user.id) if user && environment
      yield ServiceStatus.success(service) if block_given?
    else
      Pusher[service.id].trigger("deploy_event", "service_stop_error")
      CSLogger.error "Error running ServiceStoppable.stop(#{service.id})"
      yield ServiceStatus.error if block_given?
    end

    return service
  rescue => error
    service.update_attribute(:error_message,error.message)
    CSLogger.error.environment(environment.id, error.inspect)
    Pusher[service.id].trigger("deploy_event", "service_stop_error")
    yield ServiceStatus.error(error) if block_given?
    raise error
  rescue Exception => error
      service.update_attribute(:error_message,error.message)
      raise error
  end
  
  
end
