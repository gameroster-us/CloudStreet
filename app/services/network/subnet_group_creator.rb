class Network::SubnetGroupCreator < CloudStreetService

  def initialise(environment, related_services, user)
    properties = []
    properties.insert(0,{
                        form_options: {
                          type: "select",
                          options: get_existing_subnet_groups(environment)
                        },
                        name: "exisiting_subnet_groups",
                        title: "Existing Subnet Groups",
                        value: ""
    })

    properties
  end

  def get_existing_subnet_groups(environment)
    base_vpc_id = environment.vpc_ids.first
    return if base_vpc_id.nil?
    exisiting_subnet_groups = Vpc.find(base_vpc_id).subnet_groups.where.not(subnet_ids: [])
    new_objects = []
    exisiting_subnet_groups.each do |exisiting_subnet_group|
      base_subnet = []
      # if
      base_subnet_with_ids = Subnets::AWS.where(provider_id: exisiting_subnet_group.subnet_ids, vpc_id: exisiting_subnet_group.vpc_id) if !exisiting_subnet_group.subnet_ids.blank?
      # else

      subnets_data = Service.where(id: exisiting_subnet_group.subnet_service_ids)
      subnet_vpc_id = subnets_data.collect{|used_subnet| used_subnet.vpc_id}.uniq.try(:first) rescue nil
      cidr_blocks = subnets_data.collect {|obj| obj.data['cidr_block']}
      base_subnet_with_service_ids = Subnets::AWS.where(cidr_block: cidr_blocks, vpc_id: subnet_vpc_id) rescue nil
      # end
      base_subnet  = base_subnet_with_ids.try(:to_a) + base_subnet_with_service_ids.try(:to_a) rescue []
      exisiting_subnet_group.subnet_services_associated = base_subnet.compact.uniq
      if subnet_group_absent_in_environment(environment, exisiting_subnet_group)
        new_objects << exisiting_subnet_group
      end
    end
    new_objects
  end

  def subnet_group_absent_in_environment(environment, exisiting_subnet_group)
    re = environment.services.subnet_groups.where.not(state: 'terminated').where("data ->> 'uniq_provider_id' = ? OR provider_id =? AND state !=?", exisiting_subnet_group.uniq_provider_id, exisiting_subnet_group.provider_id, 'terminated').first.nil?
    re
  end

  class << self
    def create(params, user, organisation)

      subnet_group_provider_id = params[:provider_id]
      subnet_group_uniq_id = params[:uniq_provider_id]

      if subnet_group_provider_id.blank? && subnet_group_uniq_id.blank?
        @service = Services::Network::SubnetGroup::AWS.directory.non_generic_services.first
      else
        found_service = get_base_subnet_group(subnet_group_provider_id, subnet_group_uniq_id)
        attrs = found_service.attributes
        @service = Services::Network::SubnetGroup::AWS.directory.non_generic_services.first
        @service.attributes = attrs
      end
      return if @service.nil?
      @service = @service.dup
      @service.user = user

      vpc = Service.find(params[:vpc_id])
      @account = vpc.account

      environment = Environment.by_id(params[:environment_id]) if params[:environment_id] && params[:environment_id].present?
      name = params[:group_name].try(:downcase)
      @service.data = {'name_free_text' => params[:name_free_text]} if params[:name_free_text]
      service_type = CommonConstants::SERVICE_TYPE_MAP[@service.type]
      exisiting_subnet_group = EnvironmentTemplatable.check_if_sgroup_exists(@service)
      nc_params = {'service_type' => service_type, 'environment_id' => environment.id}
      nc_params.merge!(get_environment_params(environment))
      if @account.naming_convention_enabled? && exisiting_subnet_group && exisiting_subnet_group.name.include?('#')
        name = Network::SubnetGroupCreator.get_parsed_service_name(@account, user, name, @service.class, nc_params)
      elsif @account.naming_convention_enabled? && !exisiting_subnet_group
        name = Network::SubnetGroupCreator.get_parsed_service_name(@account, user, name, @service.class,nc_params)
      elsif @account.naming_convention_enabled? && !@service.provider_id
        name = @service.name
      end
      attrs = {
        state: 'environment',
        name: name,
        service_vpc_id: params[:vpc_id],
        adapter_id: environment.default_adapter_id,
        region_id: environment.region_id,
        account_id: environment.account_id,
        data: get_data(params, exisiting_subnet_group)
      }
      service_validatable = nil
      begin
        ActiveRecord::Base.transaction do
          udpate_service_attribs(@service,attrs,params)

          service_validatable = Validators::Services::Network::SubnetGroup::AWS.new({},
                                                                                    organisation.account,
                                                                                    validating_obj: @service, event: :service_creation, environment: environment)
          service_validatable.validate
          raise ActiveRecord::Rollback if service_validatable.any_error_found?
        end
      end
      return {service_creation: service_validatable.error_msgs[@service.id]} if service_validatable.any_error_found?
      @service.initialize_interface(interface_type: Protocols::SubnetGroup, depends: false)

      @service
    end

    def get_data(params, exisiting_subnet_group)
      data = {
        "description"=>params[:description].blank? ? "Subnet Group Description" : params[:description],
        "subnet_ids"=>params[:subnet_ids],
        "uniq_provider_id" => Time.now.to_f.to_s.split(".").join,
        "subnet_service_ids"=>params[:subnet_ids]
      }
      data.merge!("subnet_service_ids" => exisiting_subnet_group.subnet_service_ids, "uniq_provider_id" => exisiting_subnet_group.uniq_provider_id) if exisiting_subnet_group
      data
    end

    def get_base_subnet_group(provider_id, uniq_id)
      if provider_id.blank? && uniq_id
        SubnetGroups::AWS.where("data ->> 'uniq_provider_id' = ?", uniq_id).first
      elsif provider_id && uniq_id.blank?
        SubnetGroups::AWS.where("provider_id =?", provider_id).first
      elsif provider_id && uniq_id
        SubnetGroups::AWS.where("data ->> 'uniq_provider_id' = ? AND provider_id =?", uniq_id, provider_id).first
      else
        return nil
      end
    end

    def udpate_service_attribs(service, attrs, params)
      return false unless service.update!(attrs)
      vpc_service = create_vpc_service(service, params)
      vpc_aws = Vpcs::AWS.env_vpc(vpc_service.provider_id, service.adapter_id, service.account_id).first
      return false if vpc_aws.nil?
      service.data_will_change!
      return false unless service.update_attribute(:vpc_id, vpc_aws.id)
    end

    def create_vpc_service(service, params)
      vpc_service = Service.find(params[:vpc_id])

      Interface.find_or_create_interfaces(service, vpc_service)
      vpc_service
    end
  end
end
