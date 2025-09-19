class Services::Network::Subnet::AWS < Services::Network::Subnet
  include Services::ServiceHelpers::AWS
  include Behaviors::ReusableServicesUpdatable

  store_accessor :data, :availability_zone, :map_public_ip_on_launch, :tags, :available_ip

  attr_accessor :environment_count_required
  
  AWS_RECORD_SCOPE_METHOD = :subnets
  NETWORK_CLASS = 'Subnet'
  INTERFACES = [Services::Vpc,Services::Network::AvailabilityZone]
  after_initialize do
    @context = 'global'
    @provides = {
    }
  end

  scope :of, ->(subnet) {
    where({
      account_id: subnet.account_id,
      adapter_id: subnet.adapter_id,
      region_id: subnet.region_id,
      vpc_id: subnet.vpc_id
    }).
    where("data->>'cidr_block'=?", subnet.cidr_block).skip_deletion_states
  }

  def connected_to(service, via_services_map)
    if interfaces_includes?(service)
      case service.class.to_s
      when Services::Vpc.to_s
        return is_connected_to_vpc?(service)
      when Services::Network::AvailabilityZone.to_s
        return is_connected_to_availability_zone?(service)
      end
    end
    false
  end

  def is_connected_to_vpc?(service)
    if self.provider_data.blank?
      self.connected_via_interface_to(service)
    else
      return self.parsed_provider_data["vpc_id"].eql?(service.provider_id)
    end
  end

  def is_connected_to_availability_zone?(service)
    if self.provider_data.blank?
      self.connected_via_interface_to(service)
    else
      return self.parsed_provider_data["availability_zone"].eql?(service.parsed_data["code"])
    end
  end

  def update_hook
    "Services::VPC updating!@#"
  end

  def provision
    return if is_present_on_provider?
    CloudStreet.log "----------------------------------------------Creating #{self.class.name} #{self.inspect}"
    self.name = update_application_variables(self.name, @user) # names will only change for new subnet creation
    az_name = fetch_availability_zone_name
    tags_map = { Name: name }#.merge(env_n_app_tags)
    same_subnet_services = get_same_subnet_services
    if same_subnet_services.map(&:provider_id).uniq.compact.size > 1
      CloudStreet.log "Database Inconsistency: same_subnet_services have different provider_id !!! service_id = #{self.id}"
    end

    remote_subnet = subnet_wrapper.get_remote_subnet_with_same_cidr_and_vpc(agent: aws_compute_agent, provider_vpc_id: ::Vpc.find(self.vpc_id).vpc_id, cidr_block: self.cidr_block, az_name: az_name)
    if remote_subnet.present?
      CloudStreet.log "found remote subnet #{remote_subnet.inspect}"
      update(tags: tags_map, service_tags: get_basic_service_tag)
      save_provider_data! remote_subnet.to_json, remote_subnet.id
    else
      subnet_attrs = {}
      subnet_attrs[:vpc_id]                  = provider_vpc_id
      subnet_attrs[:cidr_block]              = cidr_block
      subnet_attrs[:availability_zone]       = az_name
      subnet_attrs[:map_public_ip_on_launch] = map_public_ip_on_launch
      CloudStreet.log "----------------------------------------------subnet_attrs=#{subnet_attrs}"

      subnet = aws_compute_agent.subnets.create subnet_attrs
      wait_till_ready subnet

      # aws_compute_agent.create_tags subnet.subnet_id, tags_map
      save_provider_data! subnet.to_json, subnet.subnet_id
      CloudStreet.log "----------------------------------------------Created #{subnet.inspect}"
    end
    update_attribute :service_vpc_id, fetch_first_remote_service(Protocols::Vpc.to_s).id
    update(tags: tags_map, service_tags: get_basic_service_tag)
    create_tag if get_associated_environments.nil? || (get_associated_environments < 2)
    Behaviors::ReusableServicesUpdatable.set_reusable_service { self.environment.services.where(id: id) }
  end

  # find all subnet with matching region, vpc_id, adapter, az and cidr_block
  def get_same_subnet_services
    az_name = fetch_availability_zone_name
    get_all_services_from_same_vpc_of_same_type.select { |s| s.cidr_block == self.cidr_block && s.fetch_availability_zone_name == az_name }
  end

  def get_attributes
    attributes.merge!('env_service_vpc_id' => parent_vpc_id)
  end

  def parent_services
    [Services::Vpc, Services::Network::AvailabilityZone, Services::Network::SecurityGroup::AWS, Services::Network::InternetGateway::AWS]
  end

  def terminate_service(params={})
    same_subnet_services = get_same_subnet_services
    service_state_to_ignore = ['terminate']
    subnet_is_being_used_in_other_environment = same_subnet_services.find do |subnet|
      provisioned = subnet.provider_id.present?
      environment_is_not_removed = ['terminating', 'terminated', 'deleting', 'deleted'].exclude?(subnet.environment.state) if subnet.environment.present?
      provisioned && environment_is_not_removed
    end

    unless subnet_is_being_used_in_other_environment
      subnet = get_remote_service
      subnet && subnet.destroy
      CloudStreet.log "-------------------------------------Attempting to terminate subnet"
      wait_till_terminated
      CloudStreet.log "-------------------------------------Terminated #{subnet.inspect}"
    end
  end

  def get_remote_service
    aws_compute_agent.subnets.get(provider_id)
  end

  def provider_data_obj
    ::ProviderData::Subnet::AWS.new(provider_data)
  end

  def update_vpc_and_depencies(vpc)
    vpc_subnets = vpc.subnets
    vpc_subnets.each do |vpc_subnet|
      next unless vpc_subnet.cidr_block == self.data['cidr_block']
      update_local_subnet(vpc_subnet)
    end
  end

  def update_local_subnet(vpc_subnet)
    self.attributes = {
      provider_data: vpc_subnet.provider_data,
      cidr_block: vpc_subnet.cidr_block,
      name: vpc_subnet.tags["Name"] || vpc_subnet.provider_id,
      tags: vpc_subnet.tags,
      available_ip: vpc_subnet.available_ip
    }
    # puts "after update inspection: #{self.inspect}"
    # additional_properties['name'] = attributes['name']
    # additional_properties_will_change!
    save!
  end

  def is_reusable?
    return {service_in_template: 0, service_in_environment: 0} if self.cidr_block.nil?
    service_in_template = self.class.in_template.where(vpc_id: self.vpc_id).where("data ->> 'cidr_block' = ?", self.cidr_block).try(:size).to_i
    service_in_environment = self.class.select('environments.id').where(vpc_id: self.vpc_id).where("services.data ->> 'cidr_block' = ?", self.cidr_block).where("environments.state != 'terminated'").joins(:environment).try(:size).to_i
    {service_in_template: service_in_template, service_in_environment: service_in_environment}
  end

  class << self

    def delete_model_service_from_provider(vpc)
     if vpc.current_user.present?
      remote_subnets = vpc.get_aws_records.subnets.all
      
      local_subnets_services = vpc.services.subnets.where.not(state: ['terminated','remove','deleted','synced_service_environmented', 'template'])

      local_subnets_services.each do |subnet_service|
       flag = 0 
       remote_subnets.each do |subnet|
         if subnet_service.provider_id == subnet.provider_id
          flag = 1
          break
        end
      end
      if flag == 0  
        if subnet_service.state == 'environment'
          #TODO RFP
          # subnet_service.update_attribute(:state, "removed_from_provider")
        else
          # subnet_service.removed_from_provider({ synchonized_by: vpc.current_user })
        end
      end
    end
  end 
end

def check_terminatable_service(service)
 Environment.joins(:environment_services).where("environment_services.service_id = ? AND  environments.state != ?" ,service.id, 'terminated')
end  

def find_and_create_service(subnet_ids, autoscaling)
  subnet_ids.each do |subnet_id|
    SubnetFetchWorker.perform_async(subnet_id, autoscaling.id)
  end
end

def fetch_remote_subnet(provider_id, autoscaling)
  environment = autoscaling.environment
  response = ProviderWrappers::AWS::Networks::Subnet.new(service: nil, agent: environment.default_adapter.connection(autoscaling.region_code)).get(provider_id)
  subnet_interfaced = autoscaling.fetch_remote_services('Protocols::Subnet').map(&:provider_id).include?(response.subnet_id)
  return if subnet_interfaced
  subnet = autoscaling.environment.services.subnets.where(provider_id: provider_id).first
  create_interface_connection(autoscaling, subnet) if subnet.present?
  create_subnet_from_remote(response, autoscaling) unless subnet.present?
end

def create_subnet_from_remote(remote_subnet, autoscaling)
  environment = autoscaling.environment
  response_hash = JSON.parse(remote_subnet.to_json)
      # return unless remote_subnet.tag_set["Name"].present?
      formatted_response = format_attributes_by_raw_data(remote_subnet)
      formatted_response.merge!({
        adapter_id: environment.default_adapter.id,
        account_id: environment.account_id,
        region_id: environment.region_id,
        provider_id: remote_subnet.subnet_id,
        provider_data: response_hash
        })
      subnet_obj = new formatted_response
      return if subnet_obj.errors.any? || subnet_obj.state != "running"
      subnet_obj.save!
      subnet_obj.environment = environment
      CloudStreet.log "new subnet-------------------------------#{subnet_obj.inspect}"
      
      fetch_or_create_interface_connection(remote_subnet, subnet_obj,  environment, autoscaling)
    end

    def fetch_or_create_interface_connection(remote_subnet, subnet_obj, environment, autoscaling)
      subnet_obj.find_or_create_default_interface_connections #default interface
      # ----vpc interface -------#
      remote_vpc_id = remote_subnet.vpc_id
      vpc_service = environment.services.vpcs.where(provider_id: remote_vpc_id).first
      subnet_obj.service_vpc_id = vpc_service.id
      subnet_obj.vpc_id = Vpcs::AWS.find_by_vpc_id(remote_vpc_id)
      subnet_obj.save!
      create_interface_connection(subnet_obj, vpc_service)


      #-------az interface------#
      availability_zone_code = remote_subnet.availability_zone
      az = environment.services.availability_zones.where("data->>'code'=?", availability_zone_code).first
      if az.present?
        create_interface_connection(subnet_obj, az)
      else
        new_az = environment.services.availability_zones.first.dup
        params = {name: 'az', code: availability_zone_code, vpc_id: vpc_service.id}
        new_az.update!(params)
        new_az.reload
        environment.services << new_az
        new_az.initialize_interface(interface_type: Protocols::AvailabilityZone, depends: false)
        create_interface_connection(subnet_obj, new_az)
      end

      #-----asg----interface-----#
      create_interface_connection(autoscaling, subnet_obj) #child- asg- parent -subnet
    end

    def create_interface_connection(child, parent)
      Interface.find_or_create_interfaces(child, parent)
    end



    #Following properties are not set
    #[:map_public_ip_on_launch]
    def format_attributes_by_raw_data(aws_service)
      {
        cidr_block: aws_service.cidr_block,
        name: aws_service.tag_set["Name"]||aws_service.subnet_id,
        availability_zone: aws_service.availability_zone,
        available_ip: aws_service.available_ip_address_count,
        state: "running",
        tags: aws_service.tag_set,
        service_tags: Services::ServiceHelpers::AWS.get_service_tags(aws_service.tag_set)
        }.merge(super)
      end
    end

    def find_free_space
      rel_geo = fetch_all_child_services.inject({ 'x' => 0, 'y' => 0 }) do |map, service|
        next(map) unless service.geometry.kind_of?(Hash)
        next(map) unless (service.kind_of?(Services::Network::AutoScaling::AWS) || service.kind_of?(Services::Compute::Server::AWS))
        map['x'] = (service.geometry['x']) if map['x'] < service.geometry['x']
        map['y'] = (service.geometry['y']) if map['y'] < service.geometry['y']
        map
      end
      abs_geo = absolute_geometry
      { 'x' => (abs_geo['x'] + rel_geo['x']), 'y' => (abs_geo['y'] + rel_geo['y']) }
    end

    def find_or_create_interface_connections(&services_context)
      return unless is_created_and_not_in_error?
      services_context.call.vpcs.each do |vpc|
        Interface.find_or_create_interfaces(self,vpc)
      end

      services_context.call.availability_zones.where("data ->> 'code' = ?", self.availability_zone).each do |az|
        Interface.find_or_create_interfaces(self,az)
      end
    end

    def edit_name(subnet_name)
      self.name = subnet_name
      unless self.state.eql?('template') || self.state.eql?('environment')
        self.service_tags||=get_basic_service_tag
        self.service_tags = (self.service_tags.collect{|service_tag|
          if service_tag["tag_key"].eql?("Name") && service_tag["applied_type"].eql?("Provider")
            get_basic_service_tag.first
          else
            service_tag
          end
        })
        self.data_will_change!
      end
      self.additional_properties = self.additional_properties.merge(name: subnet_name) if self.additional_properties.present?
      self.additional_properties_will_change!
    end

    def get_associated_environments
      fetch_associated_reusable_service_object.get_env_count.to_i 
    end

    def fetch_associated_reusable_service_object
      parser = Behaviors::ReusableServicesUpdatable.set_parser(self)
      filter = Behaviors::ReusableServicesUpdatable.network_filter(parser, self)
      ::Subnet.fetch_reusable_service(filter)
    end
    
    def self.get_remote_service_provider_id(remote_service)
      remote_service.subnet_id
    end

    private

    def set_parent_container_id
      fetch_first_remote_service("Protocols::AvailabilityZone").id if fetch_first_remote_service("Protocols::AvailabilityZone")
    end    

    def parent_service
      self.interfaces.of_type(Protocols::AvailabilityZone).first.remote_interfaces.first.service rescue nil
    end

    def is_present_on_provider?
      provider_id && aws_compute_agent.subnets.get(provider_id).present?
    end

    def fetch_remote_subnet(subnet_attrs)
      aws_compute_agent.subnets.all('vpcId' => subnet_attrs[:vpc_id], 'cidrBlock' => cidr_block).first
    end

    def fetch_n_update_subnet_from_remote(subnet_attrs)
      remote_subnet = fetch_remote_subnet(subnet_attrs)
      sync_with_remote remote_subnet
      remote_subnet
    end

    def sync_with_remote(remote_subnet)
      save_provider_data! remote_subnet.to_json, remote_subnet.subnet_id
    end

    def validate_for_termination
      attached_server = fetch_child_services(Services::Compute::Server::AWS)
      attached_loadbalancers = fetch_child_services(Services::Network::LoadBalancer::AWS)

      if attached_server.present? && (attached_server.select { |server| server.present? && server.state != 'terminated' }).present?
        service_names_str = attached_server.map { |server| server.try :name }.compact.join(', ')
        self.errors.add(:dependent_service, I18n.t('termination_validation.subnet.error_msgs.has_server_attached', service_name: service_names_str))
      end

      if attached_loadbalancers.present? && (attached_loadbalancers.select { |lb| lb.present? && lb.state != 'terminated' }).present?
        service_names_str = attached_loadbalancers.map { |lb| lb.try :name }.compact.join(', ')
        self.errors.add(:dependent_service, I18n.t('termination_validation.subnet.error_msgs.has_attached_lbs', service_name: service_names_str))
      end
    end


    def self.create_in_local(compute, service)
      vpc_id = ::Vpc.where(
        :vpc_id=>service[:vpc_id],
        :adapter_id=>service[:adapter_id],
        :region_id=>service[:region_id]
        ).pluck(:id).first
      self.create(
        account_id: service[:account_id],
        region_id: service[:region_id],
        adapter_id: service[:adapter_id],
        name: service[:name]||service[:subnet_id],
        state: 'running',
        data: {
          availability_zone: service[:availability_zone],
        map_public_ip_on_launch: ''#ToDo check the value
        },
        type: self.to_s,
        cidr_block: service[:cidr_block],
        vpc_id: vpc_id,
        provider_type: 'Providers::AWS',
        generic: false,
        geometry: {},
        provider_data: service[:provider_data],
        provider_id: service[:provider_id],
        generic_type: self.parent.to_s,
        desired_state: 'running'
        )
    end

    def self.create_on_remote(compute, service)
    #create on remote
    subnet = compute.subnets.create({
      cidr_block: service[:cidr_block],
      availability_zone: service[:availability_zone],
      vpc_id: service[:vpc_id]
      })
    create_tags(compute,subnet.subnet_id,{"Name"=> name})
    vpc_id = ::Vpc.where(
      :vpc_id=>service[:vpc_id],
      :adapter_id=>service[:adapter_id],
      :region_id=>service[:region_id]
      ).pluck(:id).first
    Service.where(provider_id: service[:provider_id],generic_type: 'Services::Network::Subnet').
    each do|service|
      service.provider_id = subnet.subnet_id
      service.provider_data = ProviderWrappers::AWS.parse_remote_service(subnet)
      service.cidr_block = subnet.cidr_block
      service.availability_zone = subnet.availability_zone
      service.vpc_id = vpc_id,
      service.save
    end
    # TODO service_vpc_id: ?
  end

    def self.create_service_object(subnet,environment) 
      subnet_service_object = self.new({
        name: subnet.name,
        cidr_block: subnet.cidr_block,
        availability_zone: subnet.availability_zone,
        available_ip: subnet.available_ip,
        state: %w[pending stopped].include?(environment.state) && (subnet.state == "pending" || subnet.state == "available") ? "environment" : "running",
        tags: subnet.tags,
        adapter_id: subnet.adapter_id,
        account_id: subnet.account_id,
        region_id: subnet.region_id,
        provider_id: subnet.provider_id,
        provider_data: subnet.provider_data,
        vpc_id: subnet.vpc_id,
        generic_type: 'Services::Network::Subnet'
      })
      subnet_service_object.save!
      subnet_service_object      
    end

  def self.update_all_related_services(reusable_service, service)
    of(reusable_service).each do |service_subnet|
      service_subnet.edit_name(service.name)
      service_subnet.save!
    end
  end
end
