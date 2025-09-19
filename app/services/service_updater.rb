class ServiceUpdater < CloudStreetService
  def self.update!(service, user, &block)
    update(service, user, ServiceUpdaterAsync, &block)
  end

  def self.update(service, user, params, starter=ServiceUpdater, &block)
    service = fetch Service, service
    user    = fetch User, user
    params = params.to_h
    service_status = {}
    service_status = service.check_service_specific_status if service.respond_to? :check_service_specific_status

    if service_status[:error]
      status ServiceStatus, service_status[:status_msg],  service_status[:response], &block
      return service
    end

    if service.terminated?
      status ServiceStatus, :already_terminated,  service, &block
      return service
    end

    action = params[:update_action]
    if action.present?
      result = service.try "can_#{action}", params
      raise CloudStreetExceptions::InvalidAction.new(service, action) if result.blank?
      if result[:error]
        status ServiceStatus, :common_error, result[:err_msg], &block
        return result
      end
    end

    begin
      CSLogger.info "----service_attribute---#{params[:service_attribute]}"
      service.assign_updatable_attributes(params[:service_attribute]) unless params[:service_attribute].blank?
      service_validatable = UpdateServiceValidatableFinder.find_and_extend!(service)
      service_validatable.perform_validations(params)
      if service_validatable.errors.any?
        error_message_map = service_validatable.errors.messages
        if (service.is_a?(Services::Compute::Server::AWS))
          error_message_map = { validation_errors: error_message_map }
        end
        status ServiceStatus, :validation_error, error_message_map, &block
        return service_validatable
      end
    rescue => e
      CSLogger.error "error while performing the validation of service #{service.id} \n"
      CSLogger.info "params were #{params.inspect}"
    end
    # if service.error?
    #   status ServiceStatus, :failed,  service, &block
    #   return service
    # end

    starter.execute(service.id, user.id, params, &block)

    # else
    #   CSLogger.info "Unable to transition service from current #{service.state} to started"
    #   status ServiceStatus, :invalid_state, service, &block
    # end
    return service
  end

  def self.execute(service, user, params, &block)
    service = fetch Service, service
    user    = fetch User, user

    CSLogger.info "Updating service #{service.id} (#{service.name}/#{service.type})"
    Pusher[service.id].trigger("deploy_event", "service_updating")

    environment = service.environment
    environment.update_attribute :updated_by, user.id
    revision_data = environment.prepare_revision_data(event: 'updated', service: service)
    service.user = user
    if ServiceUpdateable.update(service, params)
      environment.reload
      service_region = service.type.eql?("Services::Network::LoadBalancer::AWS") ? Region.find(service.region_id) : service.region
      Service.scan_threats(service.type, service.adapter, service_region, service.provider_id, false)
      # SecurityScanner.start_environment_scan(environment.id)
      service.update(updated_by: user.id)
      Events::Service::Update.create(account: service.account, service: service, environment: environment, user: user, revision_data: revision_data)
      # Events::Service::Update.create(account: service.account, service: service, user: user, environment: environment, revision: environment.revision)
  
      CSLogger.info "Successfully ran ServiceUpdateable.update(#{service.id})"
      
      ServiceEventable.send_event(service, :start)
      ServiceEventable.send_event(service, :connection_up)

      Pusher[service.id].trigger("deploy_event", "service_running")
      ::ImageUpdateWorker.perform_async(environment.id, user.id) if user && environment
      status ServiceStatus, :success, service, &block
      return true
    elsif service.errors.present? && service.errors.keys.include?(:volume_validation)
      status ServiceStatus, :aws_restriction, service, &block
      return false
    else
      CSLogger.error "Error running ServiceUpdateable.update(#{service.id})"
      Pusher[service.id].trigger("deploy_event", "service_start_error")
      status ServiceStatus, :error, service, &block
      return false
    end
  rescue Exception => error
    service.update_attribute(:error_message, error.message)
    Pusher[service.id].trigger("deploy_event", "service_start_error")
    raise error
  end

  def self.reload_service!(service, &block)
    ServiceReloaderWorker.perform_async(service.id)

    status ServiceStatus, :success, service, &block
    service
  end

  def self.reload_service(service, user, private_key, &block)
    service = fetch Service, service
    user = fetch User, user

    if service.environment.pending?
      status ServiceStatus, :success, service, &block
      return service
    end

    if service.error? && service.generic_type.eql?('Services::Network::LoadBalancer')
      status ServiceStatus, :success, service, &block
      return service
    end

    ActiveRecord::Base.transaction do
      aws_service = service.get_remote_service
      if aws_service.present?
        service.reload_service(aws_service, user)
        service.try(:decrypt_password, private_key)
        service.reload_associations(service, aws_service, user)
        environment = service.environment
        environment.update_attribute :updated_by, user.id
        revision_data = environment.prepare_revision_data(event: 'updated', service: service)
        Events::Service::Update.create(account: service.account, service: service, environment: environment, user: user, revision_data: revision_data)
        # Events::Service::Update.create(account: service.account, service: service, user: user,
                                       # environment: environment, revision: environment.revision)
      elsif service.provider_id.nil? && service.state == 'error'
        CSLogger.info "-------Service ->#{service.name}<- ----- is in error state"       
      elsif service.provider_id.nil?
        CSLogger.info "-------Service ->#{service.name}<- ----- is being created"
      else
        service.update_attribute(:state, "removed_from_provider")
      end
      if service.removed_from_provider?
        ServiceTerminator.execute(service, user, true, {}, &block)
        CSLogger.info("Successfully Terminated")
      else
        CSLogger.info("Successfully Refreshed")
        status ServiceStatus, :success, service, &block
      end
      SolrSearcher.index_objects(service)
      service
    end
  end

  def self.remove_from_environment!(service)
    user = service.user
    environment = service.environment
    revision_data = environment.prepare_revision_data(event: 'removed service from environment', service: service) if environment
    find_and_delete_interface_connections!(service)
    CostData.update_cost_data(service.id) if service.environment.present?
    service.update!(:last_cost_update_time => Time.now)
    EnvironmentService.where(service_id: service.id).destroy_all
    Events::Service::RemovedFromEnvironment.create(account: service.account, service: service, environment: environment, user: user, revision_data: revision_data) if environment
    ::ImageUpdateWorker.perform_async(environment.id, user.id) if user && environment
  end

  def self.add_to_environment!(service, environment)
    user = service.user
    EnvironmentService.find_or_create_by(environment: environment, service: service)
    service.is_service_creator = true
    service.move_synced_service_into_env(environment)
    service.find_or_create_default_interface_connections
    service.find_or_create_interface_connections{environment.services}
    if service.vpc_id.blank?
      environment_vpc = environment.environment_vpcs.first
      service.update(vpc_id:  environment_vpc.vpc_id) unless environment_vpc.blank?
    end
    revision_data = environment.prepare_revision_data(event: 'added_to_environment', service: service)
    Events::Service::AddedToEnvironment.create(account: service.account, service: service, environment: environment, user: user, revision_data: revision_data)
    ::ImageUpdateWorker.perform_async(environment.id, user.id) if user && environment
  end

  def self.find_and_delete_interface_connections!(service)
    remove_all_connection_of_service!(service)
    remove_interfaces!(service)
  end

  def self.remove_all_connection_of_service!(service)
    service.interfaces.each { |i| i.connections.destroy_all }
  end

  def self.remove_interfaces!(service)
    service.interfaces.each do |i|
      interfaces = i.interfaces
      CSLogger.info "dependent interfaces are found... removing connections #{interfaces.map { |ri| ri.service.try(:type) }}" if interfaces.present?
      i.child_connections.destroy_all
      i.destroy
    end
  end

  def self.update_service_name(service, params, user, &block)
    begin
      service.name = params[:service_attribute][:name]
      service.user = user
      service_validatable = UpdateServiceValidatableFinder.find_validatable_module(service)
      service_validatable.constantize.validate_name(params, service)
      if service.errors.any?
        error_message_map = service.errors.messages
        error_message_map = { validation_errors: error_message_map }
        status ServiceStatus, :validation_error, error_message_map, &block
        return service
      end
      environment = service.environment
      environment.update_attribute :updated_by, user.id
      if ServiceUpdateable.update_service_name(service, params)
        revision_data = environment.prepare_revision_data(event: 'updated service name', service: service)
        Events::Service::Update.create(account: service.account, service: service, environment: environment, user: user, revision_data: revision_data)
        CSLogger.info "Successfully ran ServiceUpdateable.update_service_name(#{service.id})"
        ::ImageUpdateWorker.perform_async(environment.id, user.id) if user && environment
        status ServiceStatus, :success, service, &block
        return true
      else
        CSLogger.error "Error running ServiceUpdateable.update_service_name(#{service.id})"
        status ServiceStatus, :error, service, &block
        return false
      end
    rescue Exception => error
      status ServiceStatus, :error, error.message, &block
      # raise error
    end
  end

  def self.execute_action(user, params, &block)
    if (["execute_scripts"].include? (params[:service_action]))
      service = Service.find(params[:id])
      begin
        scripts_data = {
          soe_script_ids: params[:soe_scripts_ids],
          soe_script_text: params[:soe_scripts_text]
        }
        method_name = ActionController::Base.helpers.sanitize(params[:service_action])
        service.send(method_name, scripts_data)
        status ServiceStatus, :success, service, &block
      rescue Aws::SSM::Errors::UnrecognizedClientException => e
        CSLogger.error(e.class)
        status ServiceStatus, :unauthorized, e.message, &block
      rescue Aws::SSM::Errors::AccessDeniedException => e
        CSLogger.error(e.class)
        status ServiceStatus, :unauthorized, e.message, &block
      rescue Exception => e
        CSLogger.error(e.class)
        CSLogger.error(e.message)
        CSLogger.error(e.backtrace)
        status ServiceStatus, :error, "Failed to execute scripts on instance #{service.provider_id}", &block
      end
    else
       status ServiceStatus, :success, nil, &block
    end
  end

  def self.perform_action(service, params, user, &block)
    service = fetch Service, service

    service_status = {}
    service_status = service.check_service_specific_status if service.respond_to? :check_service_specific_status

    if service_status[:error]
      status ServiceStatus, service_status[:status_msg],  service_status[:response], &block
      return service
    end

    if service.terminated?
      status ServiceStatus, :already_terminated,  service, &block
      return service
    end

    if service.execute_action(service, params, &block)
      environment = service.environment
      environment.update_attribute :updated_by, user.id
      revision_data = environment.prepare_revision_data(event: 'updated', service: service)
      Events::Service::Update.create(account: service.account, service: service, environment: environment, user: user, revision_data: revision_data) if revision_data
      status ServiceStatus, :success, service, &block
      return true
    elsif service.errors.present? && service.errors.keys.include?(:server_validation)
      status ServiceStatus, :validation_error, service, &block
      return false
    else
      status ServiceStatus, :error, service, &block
      return false
    end
    return service
  end
end
