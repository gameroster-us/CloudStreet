class Database::RdsCreator < CloudStreetService
  def initialise(environment, organisation, related_services, user)
    properties = []
    directory_rds = get_region_based_rds(environment.region_id)
    service_objs = filter_rds(directory_rds, organisation, user)
    return properties unless service_objs.present?

    service_objs.each do |service_obj|
      service_obj.adapter_id = environment.default_adapter_id
      service_obj.region_id = environment.region_id
      service_obj.account_id = environment.account_id
      service_obj.directory_region = environment.region.code
      service_obj.user = user
      properties << service_obj.properties
      if service_obj.engine.eql?('aurora')      
        properties.insert(0,{
          form_options: {
            type: 'text'
          },
          name: 'cluster_id',
          title: 'DB Cluster Identifier',
          value: service_obj.cluster_id || ""
        })

        properties.insert(1,{
          form_options: {
            type: "select",
            keepfirstblank: true,
            options: CommonConstants::PRIORITIES
          },
          name: "priority",
          title: "Priority",
          value: service_obj.priority
        })
      end
    end
    properties += form_fields(related_services) if related_services.present?
    properties += get_security_groups(environment)
    properties
  end

  def get_region_based_rds(region_id)
    region = Region.find(region_id)
    allowed_regions = CommonConstants::REGIONS - ["ap-southeast-1", "sa-east-1"]
    if allowed_regions.include?(region.code)
      Service.directory.non_generic_services.where(type: "Services::Database::Rds::AWS")
    else
      Service.directory.non_generic_services.where(type: "Services::Database::Rds::AWS").where("data ->>'engine' != ?", 'aurora')
    end    
  end

  def get_rds_params
    params = {}
    RdsConfigService::DATABASES.each do |rds|
      params.merge!(rds => {"-1" => []})
    end
    params
  end

  def build_association(user, organisation)
    account = organisation.account
    data = get_rds_params
    account.build_rds_configuration(data: data, updated_by: user.id, created_by: user.id)  
    account.save
    account.rds_configuration
  end  

  def filter_rds(rds_services, organisation, user)
    rds_configs = (organisation.account.rds_configuration.nil? ? build_association(user, organisation) : organisation.account.rds_configuration)
    everone_allowed_rds = rds_configs.data.select {|k,v| v["-1"]}.keys.collect {|key| key.gsub('_','-')}
    user_roles = user.user_roles.pluck(:id)
    specific_engine_allowed = rds_configs.data.collect{|k,v| k.gsub('_','-') if !(v.keys & user_roles).empty? }.compact if rds_configs.data
    all_rds_allowed = everone_allowed_rds + specific_engine_allowed
    rds_services.where("data ->> 'engine' IN (?) ", all_rds_allowed.uniq)
  end

  def self.create(params, user, organisation)
    sql_servers = %w(sqlserver-se sqlserver-ex sqlserver-web)
    @service = Services::Database::Rds::AWS.directory.non_generic_services.where("data ->> 'engine' = ?", params[:engine]).first
    return {service_creation: 'Invalid engine'} if @service.nil?
    @service = @service.dup
    @service.provision_service_tags = params[:service_tags]#provision_service_tags_array

    environment = Environment.by_id(params[:environment_id]) if params[:environment_id].present?

    # attrs = params.except(:environment_id, :type, :security_group_id, :action, :controller)
    # attrs.merge!(state: 'environment',
    #              adapter_id: environment.default_adapter_id,
    #              region_id: environment.region_id,
    #              account_id: environment.account_id,
    #              security_group_id: params[:security_group_id].first)

    params  = params.except(:db_name) if sql_servers.include? params[:engine]
   
    name = params[:name].try(:downcase)
    @service.data = {'name_free_text' => params[:name_free_text]} if params[:name_free_text]
    account = organisation.account

    env = Environment.find(params[:environment_id])
    env_sgs = env.services.security_groups.pluck(:provider_id)
    security_group_ids = []
    if params[:security_group_ids]
        params[:security_group_ids].each do |sg_id|
          local_sg = SecurityGroup.find(sg_id)
          group_id = (local_sg.provider_id||local_sg.uniq_provider_id)
          unless env_sgs.include? group_id
            vpc_service = env.services.vpcs.where(id: params[:vpc_id]).first 
            sg_service = local_sg.create_remote_services_from_pending(user, vpc_service, env)
            CSLogger.info "sg_service-=#{sg_service.inspect}"
          else
            CSLogger.info "Beware group is blank" if group_id.blank?
            sg_service = env.services.security_groups.where(provider_id: group_id).first
            CSLogger.info "Existing SecurityGroups found in environment : #{local_sg.provider_id}"      
          end
          security_group_ids << sg_service.id 
        end
    end
    
    params[:security_group_ids] = security_group_ids

    if account.naming_convention_enabled?
      service_type = CommonConstants::SERVICE_TYPE_MAP[@service.type][@service.engine]
      nc_params = {'service_type' => service_type, 'environment_id' => env.id} 
      nc_params.merge!(get_environment_params(environment))
      name = Database::RdsCreator.get_parsed_service_name(account, user, name, @service.class, nc_params)
    end

    attrs = {
      name: name,
      state: 'environment',
      license_model: params[:license_model],
      engine_version: params[:engine_version],
      flavor_id: params[:flavor_id],
      storage_type: params[:storage_type],
      iops: params[:iops],
      allocated_storage: params[:allocated_storage],
      multi_az: params[:multi_az],
      db_name: params[:db_name],
      master_username: params[:master_username],
      password: params[:password],
      port: params[:port],
      publicly_accessible: params[:publicly_accessible],
      backup_retention_period: params[:backup_retention_period],
      auto_minor_version_upgrade: params[:auto_minor_version_upgrade],
      backup_window: params[:backup_window],
      preferred_backup_window_duration: params[:preferred_backup_window_duration],
      preferred_backup_window_minute: params[:preferred_backup_window_minute],
      preferred_backup_window_hour: params[:preferred_backup_window_hour],
      maintenance_window: params[:maintenance_window],
      preferred_maintenance_window_duration: params[:preferred_maintenance_window_duration],
      preferred_maintenance_window_minute: params[:preferred_maintenance_window_minute],
      preferred_maintenance_window_hour: params[:preferred_maintenance_window_hour],
      preferred_maintenance_window_day: params[:preferred_maintenance_window_day],
      availability_zone: params[:availability_zone],
      adapter_id: environment.default_adapter_id,
      region_id: environment.region_id,
      service_vpc_id: params[:vpc_id],
      account_id: environment.account_id,
      subnet_group_id: params[:subnet_group_id],
      security_group_ids: params[:security_group_ids],
      cluster_id: params[:cluster_id],
      priority: params[:priority],
      is_service_creator:  true
    }
    attrs.merge!(storage_type: 'standard') unless attrs[:storage_type].present?
   
    attrs.merge!(storage_encrypted: params[:storage_encrypted]) if params[:storage_encrypted].present?
    attrs.merge!(kms_key_id: params[:kms_key_id]) if params[:storage_encrypted] && params[:kms_key_id].present?

    service_vpc = Services::Vpc.where(id: params[:vpc_id]).first
    vpc = Vpc.env_vpc(service_vpc.vpc_id, service_vpc.adapter_id, service_vpc.account_id).first if service_vpc
    attrs.merge!(vpc_id: vpc.id) if vpc.present?

    service_validatable = nil

    begin
      ActiveRecord::Base.transaction do
        return false unless @service.update!(attrs)
        service_validatable = Validators::Services::Database::Rds::AWS.new({},
         organisation.account,
         { validating_obj: @service, event: :service_creation })
        service_validatable.validate
        raise ActiveRecord::Rollback if service_validatable.any_error_found?
      end
    end
    p "eert=#{service_validatable.error_msgs.inspect}"
    return {service_creation: service_validatable.error_msgs} if service_validatable.any_error_found?

    @service.initialize_interface(interface_type: Protocols::Rds, depends: false)
    p "@service=-#{@service.inspect}"
    @service
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

  def get_security_groups(environment)
      [
      {
          form_options: {
            type: "select",
            options: get_env_sgs(environment),
            data: get_env_sgs(environment),
            required: true
          },
          name: "security_group_ids",
          title: "Security Group",
          value: get_env_sgs(environment).present? ? [get_env_sgs(environment).first[0]] : []
        }
    ]
  end

  def get_env_sgs(environment)
    vpcs = environment.vpcs
    security_group_list = {}
    if vpcs
        vpcs.each do |vpc| 
          security_groups = vpc.security_groups 
          security_groups.each do |sg|
            security_group_list.merge!({sg.id => sg.name})
          end
        end
    end
    security_group_list
  end

end
