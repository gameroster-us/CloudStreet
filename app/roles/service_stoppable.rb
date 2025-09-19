class ServiceStoppable
  def self.stop(service)
    CSLogger.info("---------ServiceStoppable.stop")

    if !service.can_stop?
      CSLogger.info "Unable to transition service from current #{service.state} to stopped"
      return false
    end

    service.desired_state = "stopped"
    service.save!

    service.stop!

    service.shutdown

    service.stopped!
    if service.is_server?
      service.calculate_up_time
      service.data_will_change!
      service.save!
    end
    return true
  rescue ::Adapters::InvalidAdapterError => e
    CSLogger.error.environment(environment.id, "Error occurred: #{message}")
    CSLogger.info message
    # Note is setting server to error required here
    service.error!
    raise e
  rescue Fog::AWS::RDS::Error, Exception => error
    unless (error.message.include?("InvalidDBInstanceState"))
      CSLogger.error error.inspect
      CSLogger.error error.backtrace
      service.error!
    end
    raise error
  end
end
