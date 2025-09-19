class Network::SecurityGroupCreator < CloudStreetService
  class << self
    def create(params, user, organisation)
      security_group_provider_id = params[:group_id]
      security_group_uniq_id = params[:uniq_provider_id]
      params.merge!(:provider_id => security_group_provider_id) 
      if security_group_provider_id.blank? && security_group_uniq_id.blank?        
        @service = Services::Network::SecurityGroup::AWS.directory.non_generic_services.first
      else
        found_service = get_base_security_group(security_group_provider_id, security_group_uniq_id)
        attrs = found_service.attributes
        @service = Services::Network::SecurityGroup::AWS.directory.non_generic_services.first
        @service.attributes = attrs
      end  

      return if @service.nil?
      @service = @service.dup
      @service.provision_service_tags = params[:service_tags]#provision_service_tags_array

      environment = Environment.by_id(params[:environment_id])
      account = environment.account 

      name = params[:name]
      @service.data = {} if @service.data.nil?
      @service.data.merge!(@service.provider_data) if @service.provider_data.present?
      @service.data.merge!({'name_free_text' => params[:name_free_text]}) if params[:name_free_text]
      existing_security_group = EnvironmentTemplatable.check_if_sg_exists(@service)
      service_type = CommonConstants::SERVICE_TYPE_MAP[@service.type]
      klass =  @service.class.to_s.split('::')[-2]
      nc_params = {'service_type' => service_type, 'environment_id' => environment.id}
      nc_params.merge!(get_environment_params(environment))
      if account.naming_convention_enabled? && existing_security_group && existing_security_group.name.include?('#')
        name = Network::SecurityGroupCreator.get_parsed_service_name(account, user, name, @service.class, nc_params)           
       elsif account.naming_convention_enabled? && !existing_security_group
        name = Network::SecurityGroupCreator.get_parsed_service_name(account,user, name, @service.class,nc_params)
      elsif account.naming_convention_enabled? && !@service.provider_id
        name = @service.name        
      end

      attrs = {
         state: 'environment',
         name: name,
         service_vpc_id: params[:vpc_id],
         adapter_id: environment.default_adapter_id,
         region_id: environment.region_id,
         account_id: environment.account_id,
         data: get_data(params, existing_security_group),
         is_service_creator:  true
      }
      attrs[:data].merge!('provision_service_tags' => @service.provision_service_tags) 

      service_validatable = nil
      begin
        ActiveRecord::Base.transaction do
          udpate_service_attribs(@service,attrs,params)
    
          service_validatable = Validators::Services::Network::SecurityGroup::AWS.new({},
           organisation.account,
           validating_obj: @service, event: :service_creation, environment: environment)
          service_validatable.validate
          raise ActiveRecord::Rollback if service_validatable.any_error_found?
        end
      end
      return {service_creation: service_validatable.error_msgs} if service_validatable.any_error_found?
      @service.initialize_interface(interface_type: Protocols::SecurityGroup, depends: false)
    
      @service
    end

    def get_data(params, existing_security_group)
      if existing_security_group && existing_security_group.state.eql?('available')
        data = existing_security_group.provider_data
        data.merge!("uniq_provider_id" => existing_security_group.uniq_provider_id)
      else
        data = {
                "group_name" => params[:name],
                "description" => params[:description]
              }
        data.merge!('uniq_provider_id'=> existing_security_group.present? ? existing_security_group.uniq_provider_id : Time.now.to_f.to_s.split(".").join)
      end  
      data
    end
   
     def get_base_security_group(provider_id, uniq_id)
      if provider_id.blank? && uniq_id
        SecurityGroups::AWS.where("data ->> 'uniq_provider_id' = ?", uniq_id).first
      elsif provider_id && uniq_id.blank?
        SecurityGroups::AWS.where("group_id =?", provider_id).first
      elsif provider_id && uniq_id
        SecurityGroups::AWS.where("data ->> 'uniq_provider_id' = ? AND group_id =?", uniq_id, provider_id).first
      else
        return nil
      end      
    end

    def udpate_service_attribs(service, attrs, params)
      return false unless service.update!(attrs)
      vpc_service = create_vpc_service(service, params)
      vpc_aws = Vpcs::AWS.env_vpc(vpc_service.provider_id, service.adapter_id, service.account_id).first
      return false if vpc_aws.nil?
      return false unless service.update(vpc_id: vpc_aws.id)
    end

    def create_vpc_service(service, params)
      vpc_service = Service.find(params[:vpc_id])

      Interface.find_or_create_interfaces(service, vpc_service)
      vpc_service
    end

    # for future refrence
    #  def get_autogenerated_name(account)
    #       service_name_count_map  = Service.get_last_used_name_per_type(nil, account)
    #       service_name_format_map = Service.get_naming_default_format_map(account)
    #       digit = service_name_count_map['Services::Network::SecurityGroup::AWS'].to_i
    #       next_digit = digit + 1
    #       name_structure = service_name_format_map['Services::Network::SecurityGroup']
    #       name = "#{name_structure}#{next_digit}"
    #       service_name_count_map['Services::Network::SecurityGroup::AWS'] = next_digit
    #       name
    # end
  end

  def initialise(environment, related_services, user)
    properties = []

    properties += form_fields(related_services) if related_services.present?

    properties.insert(0,{
      form_options: {
          type: "select",
          options: get_existing_security_groups(environment)
      },
      name: "existing_security_groups",
      title: "Existing Security Groups",
      value: ""
    })

    properties
  end

  def get_existing_security_groups(environment)
    base_vpc_id = environment.vpc_ids
    return if base_vpc_id.nil?
    vpcs = Vpc.where(id: base_vpc_id)
    new_objects = []
    vpcs.each do |vpc|
      existing_security_groups = vpc.security_groups
      existing_security_groups.each do |existing_security_group|     
        if security_group_absent_in_environment(environment, existing_security_group)        
          existing_security_group.vpc_id = environment.services.vpcs.where("provider_id=? OR data->>'vpc_id'=?", vpc.vpc_id, vpc.vpc_id).first.id
          existing_security_group.provider_id = existing_security_group.group_id
          new_objects << existing_security_group
        end        
      end
    end  
    new_objects
  end

  def security_group_absent_in_environment(environment, existing_security_group)
    re = environment.services.security_groups.where.not(state: 'terminated').where("data ->> 'uniq_provider_id' = ? OR provider_id =? AND state !=?", existing_security_group.uniq_provider_id, existing_security_group.provider_id, 'terminated').first.nil?
    re
  end

  private

  def form_fields(related_services) 
    related_services.map do |key, val|
      name_array = val.map { |service_attr_map| service_attr_map['name'] }
      {
        form_options: {
          type: "select",
          services: true,
          data: val,
          options: name_array,
          required: true
        },
        name: key,
        title: key,
        value: name_array[0]
      }
    end
  end
end
