class Network::AutoScalingCreator < CloudStreetService
  class << self
    def create(params, user, organisation)
      @service = Services::Network::AutoScaling::AWS.directory.non_generic_services.first
      return if @service.nil?
      @service = @service.dup
      @service.provision_service_tags = params[:service_tags]
      account = organisation.account
      environment = Environment.by_id(params[:environment_id]) if params[:environment_id].present?
      name = params[:name]
      @service.data = {'name_free_text' => params[:name_free_text]} if params[:name_free_text]
      
      if account.naming_convention_enabled?
        service_type = CommonConstants::SERVICE_TYPE_MAP[@service.type]
        nc_params = {'service_type' => service_type, 'environment_id' => environment.id}
        nc_params.merge!(get_environment_params(environment))
        name = Network::AutoScalingCreator.get_parsed_service_name(account, user, name, @service.class, nc_params)
      end

      attrs = {
        name: name,
        state: 'environment',
        adapter_id: environment.default_adapter_id,
        region_id: environment.region_id,
        account_id: environment.account_id,
        max_size: params[:max_size],
        min_size: params[:min_size],
        desired_capacity: params[:desired_capacity],
        health_check_grace_period: params[:health_check_grace_period],
        health_check_type: params[:health_check_type],
        default_cooldown: params[:default_cooldown],
        termination_policies: params[:termination_policies],
        is_service_creator:  true
      }
      service_validatable = nil
  
      begin
        ActiveRecord::Base.transaction do
          udpate_service_attribs(@service, attrs, params)
          service_validatable = Validators::Services::Network::AutoScaling::AWS.new({},
           organisation.account,
           validating_obj: @service, event: :service_creation, environment: environment)
          service_validatable.validate
          raise ActiveRecord::Rollback if service_validatable.any_error_found?
        end
      end
      return {service_creation: service_validatable.error_msgs} if service_validatable.any_error_found?
      @service.initialize_interface(interface_type: Protocols::AutoScaling, depends: false)
      create_launch_config_interface(@service, params[:launch_configuration_name], environment)
      CSLogger.info "@service=#{@service.inspect}"
      @service
    end

    def create_launch_config_interface(asg_service, lc_name, environment)
      return unless lc_name
      service_lc = environment.services.auto_scalling_configurations.where(name: lc_name).first
      Interface.find_or_create_interfaces(asg_service, service_lc) if service_lc
    end

    def udpate_service_attribs(service, attrs, params)
      # service.set_additional_properties!
      return false unless service.update!(attrs)
      vpc_service = create_vpc_service(service, params)
      vpc_aws = Vpcs::AWS.env_vpc(vpc_service.provider_id, service.adapter_id, service.account_id).first
      return false if vpc_aws.nil?
      return false unless service.update(vpc_id: vpc_aws.id) 
    end

    def create_vpc_service(service, params)
      subnet = Service.find(params[:vpc_zone_identifier].split(",").first)
      vpc_service = subnet.fetch_first_remote_service(Protocols::Vpc)
      Interface.find_or_create_interfaces(service, vpc_service)
      vpc_service
    end
  end
end
