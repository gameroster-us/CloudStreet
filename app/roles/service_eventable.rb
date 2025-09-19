class ServiceEventable
  def self.send_event(service, event)

    CSLogger.info "    Sending event from #{service.name} of type #{event}"

    if event == :start
      service.start_event
    end

    if event == :stop
      service.stop_event
    end

    if event == :connection_up || event == :connection_down
      service.interfaces.each do |interface|
        # CSLogger.info "interface--depends: #{interface.depends}"
        if interface.depends
          interface.remote_interfaces.each do |ri|
            CSLogger.info "      to service: #{ri.service.name} type #{ri.interface_type}"
            ri.service.send(event, service)
            if ri.service.is_volume? && service.user.present?
              action = (event == :connection_up) ? 'connected' : 'disconnected'
              if service.environment.present?
                revision_data = service.environment.prepare_revision_data(event: action, service: ri.service)
                Events::Service::Start.create(account: service.adapter.account, service: ri.service, environment: service.environment, user: service.user, revision_data: revision_data)
              end
            end
          end
        end

        if service.is_loadbalancer? && event == :connection_up
          service.get_default_interface.interfaces.each do |interface|
            if interface.service.present? && interface.service.is_server? && interface.service.provider_id.present?
              service.send(event, interface.service)
            end 
          end  
        end
      end
    end

    return true
  rescue => error
    CSLogger.error "Error while sending event, omg!"
    CSLogger.error error.inspect
    CSLogger.error error.backtrace
    service.error!
    raise error
  end
end
