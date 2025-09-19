class SecurityGroups::AWS < SecurityGroup
  extend AWSRecord::CommonAttributeMapper
  include BaseTableModules::ObjectMapper

  AWS_REMOTE_SERVICE_CLASS = "AWSRemoteServiceObject::SecurityGroup"
  SERVICE_CLASS            = "Services::Network::SecurityGroup::AWS"
  # loading it lazily because it's external service
  def aws_compute_agent
    @aws_compute_agent ||= adapter.connection(region.code)
  end

  def check_defualt_sg
    self.name == 'default'
  end
 
  # TO DO: Make this method common. i.e move it in service.rb
  def update_from_remote_service(remote_sg)
    attributes = {
      owner_id: remote_sg.owner_id,
      provider_id: remote_sg.group_id,
      description: remote_sg.description,
      provider_data:  ProviderWrappers::AWS.parse_remote_service(remote_sg),
      ip_permissions: remote_sg.ip_permissions,
      ip_permissions_egress: remote_sg.ip_permissions_egress,
      state: 'available'
    }
    update!(attributes)
  end 

  # It creates a service
  def create_remote_services_from_pending(user, vpc_service, environment, parent_service=nil)  
    if self.adapter.account.naming_convention_enabled?
      sg_service_id = environment.services.security_groups.order('created_at').last.id rescue nil
      nc_params =  {
        'service_id' => sg_service_id
      } if sg_service_id
      nc_params ||={}
      nc_params.merge!(CloudStreetService.get_environment_params(environment))
      parsed_name = Services::Network::SecurityGroup::AWS.get_parsed_service_name(self.adapter.account, user, self.name, "Services::Network::SecurityGroup::AWS", nc_params)
      self.update_attribute :name, parsed_name
    end
    sg_service = Services::Network::SecurityGroup::AWS.create_sg_service(self)
    sg_service.user = user
    sg_service.find_or_create_default_interface_connections    
    Interface.find_or_create_interfaces(sg_service, vpc_service) 
    environment.services << sg_service

    revision_data = environment.prepare_revision_data(event: 'created', service: sg_service)
    Events::Service::Create.create(account: self.adapter.account, service: sg_service, environment: environment, user: user, revision_data: revision_data) 
    SolrSearcher.index_objects(sg_service)
    state_check_obj = parent_service.nil? ? environment : parent_service
    sg_service = ServiceStarter.start(sg_service, user.id) if state_check_obj && !(["pending", "environment"].include? state_check_obj.state)
    sg_service
  end

  # will update associated templates + env services
  def update_all_reusable_service_dependencies
    associated_services = Services::Network::SecurityGroup::AWS.of(self)

    data_hash = {
      "default"=> self.name.eql?("default"),
      "group_id"=> self.group_id,
      "description"=> self.description,
      "ip_permissions"=> self.ip_permissions || [],
      "ip_permissions_egress"=> self.ip_permissions_egress || []
    }
    data_hash.merge!("uniq_provider_id" => self.data["uniq_provider_id"]) if (self.data && self.data.has_key?("uniq_provider_id"))
    associated_services.update_all(data: data_hash) # templates + environment services
  end

  def initialize_service_object
    state = self["provider_data"].nil? ? "environment" : "running"
    service_sg = Services::Network::SecurityGroup::AWS.new(
        account_id: self["account_id"],
        region_id: self["region_id"],
        adapter_id: self["adapter_id"],
        name: self["name"],
        state: state,
        data: {
          "default"=>self["name"].eql?("default"),
          "group_id"=>self["group_id"],
          "description"=>self["description"],
          "ip_permissions"=>self["ip_permissions"],
          "ip_permissions_egress"=>self["ip_permissions_egress"],
          "uniq_provider_id" => (self["data"]["uniq_provider_id"] if (self["data"] && self["data"].has_key?("uniq_provider_id")))
        },
        vpc_id: self["vpc_id"],
        provider_id: self["group_id"],
        provider_type: 'Providers::AWS',
        generic: false,
        geometry: {},
        provider_data: self["provider_data"],
        generic_type: "Services::Network::SecurityGroup",
        desired_state: state
      )

    return service_sg
  end

  def scan_and_update_threat_if_any
    SecurityScanWorker.perform_async("Services::Network::SecurityGroup::AWS",self.adapter_id,self.region_id,[self.provider_id])
  end

  class << self
    def terminate_via_reload(service)
      self.where(
        adapter_id: service.adapter_id,
        region_id: service.region_id,
        account_id: service.account_id,
        group_id: service.provider_id
        ).delete_all
    end

    def update_base_table(remote_service)
      filters = {
        adapter_id: remote_service.adapter_id,
        account_id: remote_service.account_id,
        region_id: remote_service.region_id,
        vpc_id: remote_service.vpc_id
      }
      service = where(filters.merge({group_id: remote_service.provider_id})).first
      service = service||self.new
      service.provider_id = remote_service.provider_id
      service.set_attributes = filters.merge({ 
        provider_data: remote_service.provider_data
      }).merge(format_attributes_by_raw_data(
        OpenStruct.new(remote_service.provider_data)
      ))
      service.save!
      service
    end

    def format_attributes_by_raw_data(aws_service)
      {
        name: aws_service.name||aws_service.group_id,
        description: aws_service.description,
        group_id: aws_service.group_id,
        owner_id: aws_service.owner_id,
        state: 'available',
        ip_permissions: aws_service.ip_permissions,
        ip_permissions_egress: aws_service.ip_permissions_egress
      }
    end

    def create_local_sg(remote_sg, vpc)
      new_sg =  SecurityGroup.new(
            adapter_id: vpc.adapter_id,
            account_id: vpc.account_id,
            region_id: vpc.region_id,
            vpc_id: vpc.id,
            name: remote_sg.name,
            group_id: remote_sg.group_id,
            owner_id: remote_sg.owner_id,
            provider_id: remote_sg.group_id,
            description: remote_sg.description,
            provider_data:  ProviderWrappers::AWS.parse_remote_service(remote_sg),
            ip_permissions: remote_sg.ip_permissions,
            ip_permissions_egress: remote_sg.ip_permissions_egress,
            type: "SecurityGroups::AWS",
            state: 'available'
            )
      new_sg.save
      new_sg
    end   

    def save_service_from_aws(vpc,&services_context)
      #TODO handle case if pending SG is manually created on AWS and synchronized
      filters = { adapter: vpc.adapter, account: vpc.account, region: vpc.region,vpc_id: vpc.id }
      active_service_ids = services_context.call.inject([]) do|service_ids, remote_service|
        vpc_sg = find_or_initialize_by(filters.merge(name: remote_service.name))
        vpc_sg.set_attributes = format_attributes_by_raw_data(remote_service)
        vpc_sg.provider_data = ProviderWrappers::AWS.parse_remote_service(remote_service)
        vpc_sg.save!
        service_ids << remote_service.group_id
      end

      self.where(filters).where.not(group_id: active_service_ids+[nil]).destroy_all
      Services::Network::SecurityGroup::AWS.where(filters)
        .in_environment.skip_deletion_states
        .where.not(provider_id: active_service_ids+[nil])
        .each do|security_group|
          #TODO remove this check as already checked in scope
          if security_group.environment_service
            security_group.update_attribute(:state, :removed_from_provider)
            environment = security_group.environment_service.environment
            environment.unhealthy
          end
      end
    end
  end
end