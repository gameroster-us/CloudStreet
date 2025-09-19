class ServiceTerminatable
  def self.terminate(service, params={}, user=nil)
  CSLogger.info("---------ServiceTerminatable.terminate")

    if !service.can_terminate?
      CSLogger.info "Unable to transition service from current #{service.state} to terminated"
      return false
    end

    service.desired_state = "terminated"
    service.save!
    deleted = service.removed_from_provider?
    service.terminate!
    Service.remove_scanned_data(service.type, service.adapter_id, service.provider_id)
    result = service.terminate_service(params) unless deleted
    # If service state is 'running', then we got to know that service is not terminated, due to Deletion Protection.
    return result if service.state.eql?('running')
    if service.is_server?
      starttime = service.start_time.nil? ? (service.created_time.nil? ? Time.now : service.created_time.to_time ): service.start_time.to_time
      service.up_time ||=0
      service.up_time += service.class.get_uptime(starttime)
    end
    service.terminated! unless service.state == 'error'
    environment = service.environment
    ::ImageUpdateWorker.perform_async(environment.id, user.id) if user && environment
    return true
  rescue ::Adapters::InvalidAdapterError => e
    CSLogger.error e.message.to_s
    # Note is setting server to error required here
    service.error!
    raise e
  rescue Aws::EKS::Errors::ResourceInUseException, Aws::EKS::Errors::AccessDeniedException => e
    CSLogger.error "e.message.to_s"
    CSLogger.error "****** Got Error while deleting the EKS Service | Service Id: #{service.id} | Message: #{e.message} *****"
    service.update(state: 'running') # We cannot move transition state from terminate to running thats why update attributes are used
    attrs = { code: :eks_not_deleted,
      alert_type: 'error',
      alertable_type: 'Account',
      alertable_id: service.account.id,
      additional_data: { "name": service.name, "adapter": service.adapter.name, "message": e.message.to_s }.to_json
    }
    AlertService.set_alert(attrs)
    CSLogger.error "****** Error EKS Notification send to node and update state to running again | Service Id: #{service.id} *****"
  rescue Exception => error
    CSLogger.error error.inspect
    CSLogger.error error.backtrace
    service.error!
    raise error
  end
end
