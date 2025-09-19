require 'memoist'
class Vpcs::AWS < Vpc
  extend AWSRecord::CommonAttributeMapper
  extend Memoist
  store_accessor :data, :enable_dns_hostnames, :enable_dns_resolution, :err_msg, :tags, :service_tags, :tenancy, :amazon_provided_ipv_6_cidr_block, :ipv_6_cidr_block_association_set
  # attr_accessor :unallocated_services_cost
  store_accessor :provider_data, :unallocated_services_cost, :is_draggable, :ipv_6_cidr_block_association_set

  UPDATABLE_ATTRS_LIST = %w(enable_dns_resolution enable_dns_hostnames amazon_provided_ipv_6_cidr_block)

  BUILD_OR_EDIT_MODEL_CLASS = %w(AWSRecords::Network::InternetGateway::AWS AWSRecords::Network::SecurityGroup::AWS AWSRecords::Network::RouteTable::AWS AWSRecords::Network::Nacl::AWS AWSRecords::Network::Subnet::AWS AWSRecords::Network::SubnetGroup::AWS)
  BUILD_OR_EDIT_CLASS = %w(
    Services::Vpc Services::Network::Subnet::AWS Services::Compute::Server::AWS Services::Compute::Server::Volume::AWS
    Services::Database::Rds::AWS Services::Network::ElasticIP::AWS Services::Network::LoadBalancer::AWS Services::Network::InternetGateway::AWS
    Services::Network::AutoScaling::AWS Services::Network::AutoScalingConfiguration::AWS Services::Network::SecurityGroup::AWS
    Services::Network::RouteTable::AWS Services::Network::SubnetGroup::AWS Services::Network::Nacl::AWS Services::Network::NetworkInterface::AWS
  )
  DELETE_OLD_SYNCED_SERVICE_CLASS = %w(Services::Network::Subnet::AWS)

  validates :tenancy, presence: true

  def create_sg
    security_group = fetch_default_security_group
    raise CloudStreetExceptions::ServiceAbsentOnProvider.new(self, absent_service: self, event: :vpc_creation_retry) if security_group.blank?

    save_security_group(security_group)
  end

  def create_rt
    route_table = fetch_main_route_table
    raise CloudStreetExceptions::ServiceAbsentOnProvider.new(self, absent_service: self, event: :vpc_creation_retry) if route_table.blank?

    save_route_table(route_table)
  end

  def create_nacl
    nacl = fetch_default_nacl
    raise CloudStreetExceptions::ServiceAbsentOnProvider.new(self, absent_service: self, event: :vpc_creation_retry) if nacl.blank?

    Nacl.create_default_nacl(nacl, self)
  end

  def create_ig
    internet_attached_check(aws_connection(region.code), id)
  end

  def create
    # Todo :: dev.cloudstreet.com is in test env so need to run the functionality,
    # in future we run rspec then need to change dev.cloudstreet.com's environment
    # return self.error if Rails.env.test?
    CloudStreet.log "-------------------- Call from sidekiq---#{self.inspect}"
    begin
      connection = aws_connection(region.code)
      remote_vpc = connection.vpcs.new(
        cidr_block: self.cidr,
        tenancy: self.tenancy,
        amazon_provided_ipv_6_cidr_block: (self.amazon_provided_ipv_6_cidr_block || false)
      )
      remote_vpc.save

      create_tags(connection, remote_vpc.id, { Name: name })

      remote_vpc.reload
      CloudStreet.log "-----------remote_vpc---------------#{remote_vpc.inspect}"
      if remote_vpc.id
        self.vpc_id = remote_vpc.id
        self.provider_data = ProviderWrappers::AWS.parse_remote_service(remote_vpc)
        self.tags = {Name: remote_vpc.tags["Name"]}
        self.service_tags = [{
                               "tag_key" => "Name",
                               "tag_value" => remote_vpc.tags["Name"],
                               "applied_type"=> "Provider",
                               "selected_type" => 2
        }]
        if self.save
          self.available
          security_group = fetch_default_security_group
          save_security_group(security_group) if security_group.present?
          route_table = fetch_main_route_table
          save_route_table(route_table) if route_table.present?
          nacl = fetch_default_nacl
          Nacl.create_default_nacl(nacl, self) if nacl.present?

          dns_fields = {'enable_dns_resolution' => self.enable_dns_resolution, 'enable_dns_hostnames' => self.enable_dns_hostnames}
          CloudStreet.log "-----------TO update field #{dns_fields}"
          response = update(*dns_fields.keys)
          if response[:code] == :success
            CloudStreet.log "------Successfully updated VPC dns field "
            true
          else
            self.err_msg = 'failed_to_update_dns_fields'
            self.save
            self.error
            CloudStreet.log "------Error While updating VPC dns field "
            false
          end
        else
          self.err_msg = 'failed_to_update_vpc'
          self.save
          self.error
          false
        end
      end
    rescue Fog::Compute::AWS::Error => error
      self.error
      case error.message
      when /VpcLimitExceeded/
        self.err_msg = I18n.t('errors.vpc_limit_exceeded')
        self.save
        CloudStreet.log "--------IN vpc_limit_exceeded"
      when /InternetGatewayLimitExceeded/
        raise CloudStreetExceptions::ProviderResourceLimitExceeded.new(self, exceeded_resource: :internet_gateway)
        CloudStreet.log "--------IN ig_limit_exceeded"
      else
        self.err_msg = error.message
        self.save
        CloudStreet.log "--------IN failed_to_create"
      end
      false
    rescue Adapters::InvalidAdapterError => e
      CloudStreet.log e.message
      self.err_msg = I18n.t('errors.service_invalid_adapter')
      self.save
      self.error
      CloudStreet.log "----------IN rescue #{e.class}"
      false
    rescue Exception => e
      if e.class.to_s == "CloudStreetExceptions::ProviderResourceLimitExceeded"
        self.internet_attached = false
        self.err_msg = I18n.t('errors.failed_to_create_ig')
        self.save
        self.error
        CloudStreet.log "----------IN rescue when ig limit exceeded #{e.class}"
        raise CloudStreetExceptions::ProviderResourceLimitExceeded.new(self, exceeded_resource: :internet_gateway)
      elsif e.class.to_s == 'CloudStreetExceptions::ServiceAbsentOnProvider'
        self.internet_attached = false
        self.err_msg = I18n.t('errors.vpc_limit_exceeded')
        self.save
        self.error
        CloudStreet.log "----------IN rescue when vpc limit exceeded #{e.class}"
        raise CloudStreetExceptions::ServiceAbsentOnProvider.new(self, exceeded_resource: :vpc)
      end
      self.err_msg = I18n.t('errors.failed_to_create_vpc')
      self.save
      self.error
      CloudStreet.log "------Vpc couldn't be created - #{e.class}"
      false
    end
  end

  def create_attach_save_ig
    remote_ig = create_attach_ig
    save_ig remote_ig
    create_default_route
  end

  def create_attach_ig
    begin
      internet_gateway = aws_connection(region.code).internet_gateways.create
      internet_gateway.attach vpc_id
      CloudStreet.log "--------------remote internet_gateway-------------------#{internet_gateway.inspect}"
      internet_gateway
    rescue Fog::Compute::AWS::Error=>error
      puts "--------error-----#{error.message}"
      case error.message
      when /InternetGatewayLimitExceeded/
        self.internet_attached = false
        raise CloudStreetExceptions::ProviderResourceLimitExceeded.new(self, exceeded_resource: :internet_gateway)
      end
    end
  end

  def save_ig(remote_ig)
    CloudStreet.log "--------------vpcid----------------------------#{vpc_id}-----#{id}"
    reload
    CloudStreet.log "--------------vpcid----------------------------#{vpc_id}-----#{id}"

    self.create_internet_gateway!(
      provider_data:  ProviderWrappers::AWS.parse_remote_service(remote_ig),
      provider_id: remote_ig.id,
      # state:remote_ig.attachment_set['state'],
      state: 'created',
      vpc_id:     id,
      account_id: account_id,
      adapter_id: adapter_id,
      region_id:  region_id,
      type: 'InternetGateways::AWS'
    )
  end

  def create_default_route
    CloudStreet.log "-------------------------creating default route '0.0.0.0/0' for ig"
    route_params = self.route_table.get_route_default_ig_params if self.route_table.present?
    RouteTables::Rules.create_route(self.route_table, route_params)
  end

  def create_on_aws
    provision

    security_group = fetch_default_security_group
    update_security_group(security_group) if security_group.present?
    route_table = fetch_main_route_table
    update_route_table(route_table) if route_table.present?
    nacl = fetch_default_nacl
    Nacl.update_default_nacl(nacl, self) if nacl.present?
    is_saved
  end

  def provision
    connection = aws_connection(region.code)
    remote_vpc = connection.vpcs.new(
      cidr_block: cidr,
      tenancy: tenancy,
      enable_dns_support: enable_dns_resolution
    )

    remote_vpc.save
    create_tags(connection, remote_vpc.id, { Name: name })
    remote_vpc.reload
    self.vpc_id = remote_vpc.id
    self.provider_data = ProviderWrappers::AWS.parse_remote_service(remote_vpc)
    update_attribute :enable_dns_hostnames, false
    self.tags =  {Name: name}
    is_saved = save

    self.available
    security_group = fetch_default_security_group
    save_security_group(security_group) if security_group.present?
    route_table = fetch_main_route_table
    save_route_table(route_table) if route_table.present?
    nacl = fetch_default_nacl
    Nacl.create_default_nacl(nacl, self) if nacl.present?

    self.provider_data["enable_dns_resolution"] = enable_dns_resolution
    self.provider_data["enable_dns_hostnames"] = enable_dns_hostnames
    self.update(*self.provider_data.keys)
  end

  def already_present_on_aws
    connection = aws_connection(region.code)
    remote_vpc = connection.vpcs.get(self.vpc_id)
    remote_vpc.nil? ? false : true
  end

  def fetch_default_nacl
    return if self.vpc_id.blank?
    agent = ProviderWrappers::AWS::VpcProvider.compute_agent(adapter, region.code)
    ProviderWrappers::AWS::VpcProvider.get_default_nacl(agent, self.vpc_id)
  end

  def fetch_default_security_group
    return if self.vpc_id.blank?

    # TO DO: instead of using first should filter by vpc-id and groupname and description
    aws_connection(region.code).security_groups.all({'vpc-id' => self.vpc_id,'group-name'=>'default'}).first
  end

  def fetch_main_route_table
    return if self.vpc_id.blank?
    # TO DO: instead of using first should filter by vpc-id and routes
    aws_connection(region.code).route_tables.all('vpc-id' => self.vpc_id).first
  end

  def update(*attrs)
    connection = aws_connection(region.code)
    vpc_params = UPDATABLE_ATTRS_LIST.inject({}) { |hash, attr_name| hash[attr_name] = send(attr_name); hash }
    # ipv6_block = to_bool vpc_params['amazon_provided_ipv_6_cidr_block']
    vpc_params = vpc_params.except('amazon_provided_ipv_6_cidr_block')
    vpc_params.slice(*attrs).each do |key, value|
      next if value.nil?
      attr_name = getAttributeName(key)
      begin
        response = connection.modify_vpc_attribute(vpc_id, attr_name => value)
      rescue Fog::Compute::AWS::NotFound => e
        return {code: :not_found}
        #return false
      rescue Fog::Compute::AWS::Error => e
        CloudStreet.log e.message
        return {code: :error}
      end
    end
    internet_attached_check(connection, id)
    # puts "ipv6_block-----#{ipv6_block}"
    # update_ipv6 = connection.associate_vpc_cidr_block(vpc_id, ipv6_block)
    #     puts "update_ipv6----#{update_ipv6.inspect}"
    remote_vpc = connection.vpcs.get(vpc_id)
    self.provider_data = ProviderWrappers::AWS.parse_remote_service(remote_vpc)
    return {code: :success}
  end

  def internet_attached_check(connection, id)
    if internet_attached && self.internet_gateway # When Ig is present and attached
      process_ig(connection, id, "attach")
      self.internet_gateway.created # change state to created
      CloudStreet.log "-----------state when attched---------------#{self.internet_gateway.state}"
    elsif  !internet_attached &&  self.internet_gateway # When Ig is presenet and not attached
      associated_lb = Services::Network::LoadBalancer::AWS.find_by_vpc_id(id) rescue "not_found"
      external_lb_check = associated_lb.scheme rescue "not_found"
      elastic_ip_check = Services::Network::ElasticIP::AWS.find_by_vpc_id(id) rescue "not_found"
      if external_lb_check != "internet-facing" && elastic_ip_check.nil?
        process_ig(connection, id, "detach")
        self.internet_gateway.archived
        CloudStreet.log "-----------state when detached---------------#{self.internet_gateway.state}"
      else

        raise_exception_when_ig_cannot_detach(external_lb_check,elastic_ip_check)

        self.internet_gateway.created
        return false
      end
    elsif internet_attached && !self.internet_gateway #when ig is not assigned while vpc creation and commanded to attach
      create_attach_save_ig if self.internet_attached
      CloudStreet.log "-----------state when created---------------#{self.internet_gateway.state}"
      # else
      #   CloudStreet.log "--------Why are you here .. go check your code-----------#{self.internet_gateway}"
    end
  end

  def raise_exception_when_ig_cannot_detach(elb,eip)
    if elb != "not_found"
      raise CloudStreetExceptions::ServiceIsDependent.new(self, dependent_service: elb , event: :elb)
    elsif eip != "not_found"
      raise CloudStreetExceptions::ServiceIsDependent.new(self, dependent_service: eip , event: :eip)
    end
  end


  def process_ig(connection, id, method)
    vpc = Vpc.find(id)
    ig_id = vpc.internet_gateway.provider_id
    response = connection.internet_gateways.get(ig_id)
    puts "-----response-----#{response.inspect}"
    if (method == "attach" && vpc.internet_gateway.can_archived?)
      connection.create_route(vpc.route_table.provider_id,'0.0.0.0/0',vpc.internet_gateway.provider_id) #adding route
      CloudStreet.log "-----------updating-IG-------attach-------"
    elsif (method == "detach" && vpc.internet_gateway.can_created?)
      CloudStreet.log "-----------updating-IG--------detach------"
    else
      # connection.create_route(vpc.route_table.provider_id,'0.0.0.0/0',vpc.internet_gateway.provider_id) #adding route
      begin
        if method == "attach"
          response.send(method,vpc.vpc_id)
        elsif method == "detach" && response.attachment_set["vpcId"] == vpc.vpc_id
          response.send(method,vpc.vpc_id)
        end
      rescue Exception => e
        CloudStreet.log "---------attach exception----------------#{e.message}"
        raise CloudStreetExceptions::ProviderDependencyViolation.new(self, dependent_service: vpc.internet_gateway , event: :ig)
      end
    end
  end

  def getAttributeName(key)
    case key
    when 'enable_dns_resolution'
      return "EnableDnsSupport.Value"
    when 'enable_dns_hostnames'
      return "EnableDnsHostnames.Value"
    when 'enable_dns_support'
      return "EnableDnsSupport.Value"
    else "No match found"
    end
  end

  def get_associated_subnets
    Services::Network::Subnet::AWS.provisioned.where(state: 'running', vpc_id: self.id)
  end

  # def get_associated_route_tables
  #   connection = aws_connection(region.code)
  #   route_table_details = connection.route_tables.all("vpc-id" => self.vpc_id)
  #   hash_route_table_details = {}
  #   arr_route_table_details = Array.new
  #   route_table_details.each do |route_table|
  #     hash_route_table_details = {route_table_id: route_table.id, routes: route_table.routes, vpc_id: route_table.vpc_id, associations: route_table.associations, name: route_table.tags["Name"]}
  #     arr_route_table_details << hash_route_table_details
  #   end
  #   return arr_route_table_details
  # end

  def get_associated_internet_gateways
    # connection = aws_connection(region.code)
    # internet_gateway_details = connection.internet_gateways.all
    # hash_internet_gateway_details = {}
    # arr_internet_gateway_details = Array.new
    # internet_gateway_details.each do |internet_gateway|
    #   if internet_gateway.attachment_set["vpcId"].eql?(self.vpc_id)
    #     hash_internet_gateway_details = {internet_gateway_id: internet_gateway.id, name: internet_gateway.tag_set['Name'], vpc_id: internet_gateway.attachment_set["vpcId"]}
    #     arr_internet_gateway_details << hash_internet_gateway_details
    #   end
    # end
    # return arr_internet_gateway_details
  end

  def self.initialize_or_edit_from_remote(remote_vpc_info)
    filters = {
      vpc_id: remote_vpc_info.provider_vpc_id,
      adapter_id: remote_vpc_info.adapter_id,
      account_id: remote_vpc_info.account_id,
      region_id: remote_vpc_info.region_id
    }
    vpc = where(filters).first || Vpcs::AWS.new
    vpc.synchronized = false unless vpc.persisted?
    attributes = get_data_store_attributes(remote_vpc_info).merge({
                                                                    data: remote_vpc_info.data
    })
    vpc.set_attributes = attributes
    vpc.unallocated_services_cost = (remote_vpc_info.data["unallocated_services_cost"]||0.0)
    vpc
  end

  def initialize_or_edit_dependencies_from_remote(service_type=nil)
    classes = service_type.present? ?  [service_type] : BUILD_OR_EDIT_CLASS
    classes.each do |klass|
      klass.constantize.build_or_edit_vpc_services_from_provider(self)
    end
  end

  def get_aws_records
    AWSRecord.where(account_id: account_id, adapter_id: adapter_id, region_id: region_id,provider_vpc_id: vpc_id)
  end

  # def save_with_dependencies
  #   ActiveRecord::Base.transaction do
  #     service_list = services.select{|s| s.is_synced_service? }.to_a.sort!{ |service_x, service_y|
  #        service_x.draw_order <=> service_y.draw_order
  #     }
  #     save_interface_connections
  #     self.services.synced_services.each do|service|
  #       # service.user = current_user
  #       service.set_additional_properties!
  #       service.save!
  #     end
  #     self.update_attribute(:synchronized, true)
  #   end
  # end

  def protocol
    "Protocols::Vpc"
  end

  def get_unallocated_vpc_service
    self.services.vpcs.select{ |service| service.environment.nil? }.first
  end

  def get_unallocated_services
    draw_order = "case generic_type"
    SERVICE::SERVICE_DRAW_ORDER.each_with_index do |i, j|
      draw_order += " when '#{i}' then #{j+1}"
    end
    draw_order += " end"
    self.services.synced_services.order(draw_order)
  end

  def mark_unhealthy_services(current_user:)
    changed_env_arr = mark_unhealthy_services_for_removal current_user: current_user
    changed_env_arr = (changed_env_arr + mark_unhealthy_services_for_new_services(current_user: current_user)).uniq
    Environment.increment_minor_revision changed_env_arr
    mark_synchronized!
  end

  def remove_from_provider
    #TODO use wrapper
    aws_vpc = aws_connection(get_region_code).vpcs.get(vpc_id)
    aws_vpc.destroy if aws_vpc.present?
  end

  def aws_compute_agent
    @aws_compute_agent ||= adapter.connection(region.code)
  end

  def services_vpcs
    Services::Vpc.where("data->>'vpc_id' = ?", self.vpc_id)
  end
  memoize :services_vpcs

  def update_related_environments
    services_vpcs.each do |service_vpc|
      service_vpc.data['enable_dns_resolution'] = enable_dns_resolution
      service_vpc.data['enable_dns_hostnames'] = enable_dns_hostnames
      service_vpc.data['internet_attached'] = internet_attached
      service_vpc.data_will_change!
      service_vpc.save
    end
  end

  def update_unallocated_services_cost!
    self.unallocated_services_cost = self.services.synced_services.chargeable_services.sum(:cost_by_hour)
    self.save(validate: false)
  end

  private

  def to_bool(string)
    return true if string =~ (/^(true|t|yes|y|1)$/i)
    return false if string.nil? || string =~ (/^(false|f|no|n|0)$/i)
    raise ArgumentError, "invalid value: #{string}"
  end

  def mark_unhealthy_services_for_new_services(current_user:)
    CloudStreet.log '--------- Marking new created services as unhealthy'
    self.services.synced_services.volumes.inject([]) do |changed_env_arr, service|
      server_id = service.provider_data["server_id"]
      next(changed_env_arr) if server_id.blank?
      environmented_server = account.services.instance_servers.in_environment.where(provider_id: server_id, adapter_id: adapter_id, region_id: region_id).first
      next(changed_env_arr) if environmented_server.blank?
      CloudStreet.log "Found environmented server: #{environmented_server.id} for volume: #{service.id}"
      service.environment = environmented_server.environment
      service.save unless service.persisted?
      Services::SyncProviderDataWorker.perform_async(environmented_server.id)
      service.class.create_interfaces_n_connections(service, environmented_server)
      service.synced_service_environmented({ synchonized_by: current_user })
      changed_env_arr << service.environment
    end
  end

  def mark_unhealthy_services_for_removal(current_user:)
    #ToDo refine query with environment_vpcs performance enhancement
    self.environments.inject([]) do |changed_env_arr, environment|
      unhealthy_services = environment.get_unhealthy_vpc_services(vpc_id)
      changed_env_arr << environment if unhealthy_services.present?
      unhealthy_services.each do|service|
        service.removed_from_provider({ synchonized_by: current_user })
      end
      changed_env_arr
    end
  end

  def mark_synchronized!
    self.update_attribute(:synchronized, true)
  end

  def save_interface_connections
    unallocated_services = get_unallocated_services
    unallocated_services.each do |service|
      service.find_or_create_default_interface_connections
    end
    unallocated_services.each do |service|
      service.find_or_create_interface_connections{
        self.services.synced_services
      }
    end
  end

  def save_security_group(remote_security_group)
    filters = {
      name: remote_security_group.name,
      vpc_id: id, account_id: account_id,
      adapter_id: adapter_id, region_id: region_id,
      group_id: nil, owner_id: nil, state: 'pending'
    }
    default_pending_sg = SecurityGroup.find_by(filters)
    if default_pending_sg
      update_default_sg(default_pending_sg, remote_security_group)
    else
      save_default_sg(remote_security_group)
    end
  end

  def update_default_sg(default_pending_sg, remote_security_group)
    update_params = {
      description: remote_security_group.description,
      group_id: remote_security_group.group_id,
      owner_id: remote_security_group.owner_id,
      provider_data: ProviderWrappers::AWS.parse_remote_service(remote_security_group),
      ip_permissions: remote_security_group.ip_permissions || [],
      ip_permissions_egress: remote_security_group.ip_permissions_egress || [],
      state: 'available'
    }
    default_pending_sg.update_attributes(update_params)
  end

  def save_default_sg(remote_security_group)
    SecurityGroup.create(
      name:           remote_security_group.name,
      description:    remote_security_group.description,
      group_id:       remote_security_group.group_id,
      owner_id:       remote_security_group.owner_id,
      provider_data:  ProviderWrappers::AWS.parse_remote_service(remote_security_group),
      ip_permissions: remote_security_group.ip_permissions || [],
      ip_permissions_egress: remote_security_group.ip_permissions_egress || [],
      type:       'SecurityGroups::AWS',
      vpc_id:     id,
      account_id: account_id,
      adapter_id: adapter_id,
      region_id:  region_id,
      state: 'available'
    )
  end

  def save_route_table(remote_route_table)
    RouteTable.create!(
      routes:         remote_route_table.routes || [],
      provider_id:    remote_route_table.id,
      name:           remote_route_table.tags['Name'] || 'main',
      associations:   remote_route_table.associations || [],
      provider_data:  ProviderWrappers::AWS.parse_remote_service(remote_route_table),
      type:           'RouteTables::AWS',
      vpc_id:         id,
      account_id:     account_id,
      adapter_id:     adapter_id,
      region_id:      region_id
    )
  end

  def update_security_group(remote_security_group)
    security_group = SecurityGroup.find_by_group_id(remote_security_group.group_id)
    return unless security_group
    security_group.update_attributes(
      name:           remote_security_group.name,
      description:    remote_security_group.description,
      group_id:       remote_security_group.group_id,
      owner_id:       remote_security_group.owner_id,
      provider_data:  ProviderWrappers::AWS.parse_remote_service(remote_security_group),
      ip_permissions: remote_security_group.ip_permissions || [],
      ip_permissions_egress: remote_security_group.ip_permissions_egress || [],
      type:       'SecurityGroups::AWS',
      vpc_id:     id,
      account_id: account_id,
      adapter_id: adapter_id,
      region_id:  region_id
    )
  end

  def update_route_table(remote_route_table)
    route_table = RouteTable.find_by_provider_id(remote_route_table.id)
    return unless route_table
    route_table.update_attributes(
      routes:         remote_route_table.routes || [],
      provider_id:    remote_route_table.id,
      name:           remote_route_table.tags['Name'] || 'main',
      associations:   remote_route_table.associations || [],
      provider_data:  ProviderWrappers::AWS.parse_remote_service(remote_route_table),
      type:           'RouteTables::AWS',
      vpc_id:         id,
      account_id:     account_id,
      adapter_id:     adapter_id,
      region_id:      region_id
    )
  end

  def aws_connection(region_name)
    @aws_connection ||= adapter.connection region_name
  end

  def create_tags(connection, vpc_id, tag_map)
    connection.create_tags vpc_id, tag_map
  end

  def self.create_in_local(compute, service)
    #create tags
    unless (service[:tags]["environment"] ||service[:tags]["status"])
      un_allocated_tag = {'status'=> 'unallocated'}
      create_tags(compute, service[:provider_id], un_allocated_tag)
      service[:provider_data]["tags"].merge!(un_allocated_tag)
    end

    vpc_name = service[:tags]["Name"]||service[:vpc_id]
    name_exists = Vpcs::AWS.where(account_id: service[:account_id],region_id: service[:region_id],name: vpc_name).count > 0
    vpc = ::Vpcs::AWS.create!({
      name: name_exists ? service[:vpc_id] : vpc_name,
      account_id: service[:account_id],
      region_id: service[:region_id],
      adapter_id: service[:adapter_id],
      vpc_id: service[:vpc_id],
      provider_data: service[:provider_data],
      cidr: service[:cidr],
      enabled: true,
      enable_dns_resolution: service[:enable_dns_resolution],
      internet_attached: service[:internet_attached],
      tenancy: service[:tenancy],
      enable_dns_support: service[:enable_dns_support],
      type: "Vpcs::AWS",
      data: {"enable_dns_hostnames"=>false}
    })
  end

  def self.create_on_remote(compute, service)
    #create on remote
    vpc = compute.vpcs.create({
      cidr_block: service[:cidr],
      tenancy: service[:tenancy],
      enable_dns_support: service[:enable_dns_support]
    })

    create_tags(compute, vpc.id, {"Name"=> service[:tags]["Name"]||vpc.id,"Environment"=>"unallocated"})

    vpc.reload
    #update dependancies in local
    Vpc.where(vpc_id: service[:vpc_id]).update_all({
      name: service[:name],
      vpc_id: vpc.id,
      provider_data: ProviderWrappers::AWS.parse_remote_service(vpc),
      tenancy: vpc.tenancy,
      cidr: vpc.cidr_block
    })

    Service.where(provider_id: service[:vpc_id],generic_type: 'Services::Vpc').
    each do|service|
      service.name = service[:name]
      service.provider_id = vpc.id
      service.cidr_block = vpc.cidr_block
      service.provider_data = ProviderWrappers::AWS.parse_remote_service(vpc)
      service.tenancy = vpc.tenancy
      serivce.ipv_6_cidr_block_association_set = vpc.ipv_6_cidr_block_association_set
      service.amazon_provided_ipv_6_cidr_block = (vpc.amazon_provided_ipv_6_cidr_block || false)
      service.save
    end

    filters={
      region_id: service[:region_id],
      adapter_id: service[:adapter_id]
    }
    update_dependencies_old_vpc_id_with_new_vpc_id(service[:vpc_id],vpc.id,filters)
    # TODO service_vpc_id: ?
  end

  def self.update_dependencies_old_vpc_id_with_new_vpc_id(old_id,new_id,filters)
    vpc = Vpcs::AWS.find_by_vpc_id(new_id)
    [RouteTable, SecurityGroup, Service].each do |klass|
      klass.where(filters).each do|service|
        if service.provider_data && service.provider_data["vpc_id"] && service.provider_data["vpc_id"].eql?(old_id)
          service.update_attributes(:provider_data=>service.provider_data.merge("vpc_id"=>new_id),:vpc_id=> vpc.try(:id))
        end
      end
    end
  rescue Exception => e
    pp e.inspect
    pp e.backtrace
  end

  def terminate_service(params={})
    #NOTE : Do not delete main RouteTable
    # raise "cannot delete main route table"
    unless main.eql?('true')
      route_table = get_remote_service
      route_table && route_table.destroy
      CloudStreet.log "-------------------------------------Attempting to terminate route table"
      wait_till_terminated
      CloudStreet.log "-------------------------------------Terminated #{route_table.inspect}"
    end
  end

  def get_remote_service
    aws_compute_agent.route_tables.get(provider_id)
  end

  class << self
    def terminate_via_reload(service)
      self.where(
        adapter_id: service.adapter_id,
        region_id: service.region_id,
        account_id: service.account_id,
        vpc_id: service.provider_id
      ).update_all(state: :archived)
    end

    def update_base_table(remote_service)
      filters = {
        vpc_id: remote_service.provider_id,
        adapter_id: remote_service.adapter_id,
        account_id: remote_service.account_id,
        region_id: remote_service.region_id
      }
      service = where(filters).first || self.new
      #service.synchronized = false unless service.persisted?
      service.synchronized = true
      service.provider_data =  remote_service.provider_data
      service.attributes = format_attributes_by_raw_data(
        OpenStruct.new(remote_service.provider_data)
      ).merge(filters).stringify_keys
      # TODO add after callback service.unallocated_services_cost = (remote_service.data["unallocated_services_cost"]|| 0)
      service.internet_attached = remote_service.internet_attached
      service.internet_gateway.destroy if !service.internet_attached && service.internet_gateway
      service.state="available"
      service.save! if service.changed?
      service
    end

    def update_base_table_from_aws_record(remote_service)
      filters = {
        vpc_id: remote_service.provider_id,
        adapter_id: remote_service.adapter_id,
        account_id: remote_service.account_id,
        region_id: remote_service.region_id
      }
      service = where(filters).first || self.new
      service.synchronized = false unless service.persisted?
      service.set_attributes = get_data_store_attributes(remote_service).merge({
                                                                                 provider_data: remote_service.data
      })
      # TODO add after callback service.unallocated_services_cost = (remote_service.data["unallocated_services_cost"]|| 0)
      service.internet_attached = remote_service.data["internet_attached"]
      service.state="available"
      service.save! if service.changed?
      service
    end

    def format_attributes_by_raw_data(aws_service)
      {
        name: aws_service.tags["Name"] || aws_service.id,
        vpc_id: aws_service.id,
        internet_attached: aws_service.internet_attached,
        cidr: aws_service.cidr_block,
        tenancy: aws_service.tenancy,
        state: "available",
        enable_dns_hostnames: aws_service.try(:enable_dns_hostnames),
        enable_dns_resolution: aws_service.try(:enable_dns_resolution),
        amazon_provided_ipv_6_cidr_block:  aws_service.try(:amazon_provided_ipv_6_cidr_block),
        ipv_6_cidr_block_association_set: (aws_service.try(:ipv_6_cidr_block_association_set) || false)
      }
    end
  end
end
