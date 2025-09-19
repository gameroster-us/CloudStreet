class Services::Network::RouteTable::AWS < Services::Network::RouteTable
  include Services::ServiceHelpers::AWS
  store_accessor :data, :main, :route_table_id, :routes, :associations, :tags, :association_conflict, :associated_vpc_id
 
  scope :find_by_association_id, -> (association_id, adapter, region_id){ sql = "SELECT  s.* FROM services s, json_array_elements(s.provider_data->'associations') associations WHERE s.type IN ('Services::Network::RouteTable::AWS') and associations->>'routeTableAssociationId' = '#{association_id}' and adapter_id = '#{adapter.id}' and account_id = '#{adapter.account_id}' and region_id = '#{region_id}'"
                                                                          Services::Network::RouteTable::AWS.find_by_sql(sql)
                                                                          }
  UPDATABLE_ATTRS = [:associations, :name]
  AWS_RECORD_SCOPE_METHOD = :route_tables
  NETWORK_CLASS = 'RouteTable'
  INTERFACES = [Services::Vpc,Services::Network::Subnet::AWS, Services::Compute::Server::AWS ]

  def connected_to(service, via_services_map)
    if interfaces_includes?(service)
      case service.class.to_s
      when Services::Vpc.to_s
        return is_connected_to_vpc?(service)
      when Services::Network::Subnet::AWS.to_s
        return is_connected_to_subnet?(service, via_services_map)
      when Services::Compute::Server::AWS.to_s
        return is_connected_to_server?(service, via_services_map)
      end
    end
    false
  end

  def is_connected_to_vpc?(service)
    if self.parsed_provider_data.blank?
      self.connected_via_interface_to(service)
    else
      self.parsed_provider_data["vpc_id"].eql?(service.provider_id)
    end
  end

  def is_connected_to_subnet?(service, via_services_map)
    if self.parsed_provider_data.blank?
      self.connected_via_interface_to(service)
    else
      servers = (via_services_map['Services::Compute::Server::AWS']||[]).map{|server| server if self.routes.map{|r| r['instance_id']}.include? server.provider_id}.compact
      subnet_ids = servers.map{|s| s.provider_data['subnet_id']}.compact if servers.present?
      ((self.parsed_provider_data["associations"].any?{|association| association["subnetId"].eql?(service.provider_id)}) || ((subnet_ids.include? service.provider_id) if subnet_ids.present?))
    end
  end

  def is_connected_to_server?(service, via_services_map)
    self.routes = self.routes.collect do|route|
      if route["instance_id"].present?
        instance = (via_services_map['Services::Compute::Server::AWS']||[]).find{|server| server.provider_id.eql?(route["instance_id"])}
        if instance.present?
          route["connected_service"]=instance.private_ip_address
          route["connected_service_id"] = instance.id
          route["connected_service_name"] = instance.name
          route["destinationCidrBlock"] = route["destinationCidrBlock"]
          route["instance_id"] = route["instance_id"]
        end
      end
      route
    end
    self.routes.pluck('instance_id').include?(service.data['instance_id'])
  end

  def provision
    return if provider_id.present? # i.e. don't create if it's already created
    CloudStreet.log "----------------------------------------------Creating #{self.class.name} #{self.inspect}"
    self.name = update_application_variables(self.name, @user)
    if is_main?
      route_table = save_route_table_from_aws
      save_ig_routes(route_table)
      update(service_tags: get_basic_service_tag)
    else
      route_table = aws_compute_agent.route_tables.create route_table_attrs
      save_provider_data! route_table.to_json, route_table.id
      tags_map = { Name: name }

      aws_compute_agent.create_tags route_table.id, tags_map
      update(service_vpc_id: fetch_first_remote_service(Protocols::Vpc).id, service_tags: get_basic_service_tag)
      save_ig_routes(route_table)

      get_additional_server_routes.each do |additional_route|
        instance_route = get_route_instance_params(additional_route)
        additional_route = route_table_wrapper.create_server_route(route_table.id, instance_route[:destination_cidr_block], instance_route[:instance_id])
        CloudStreet.log "----------------------created additional_route server-----------#{additional_route.inspect}"
      end
    end

    # Fetch the subnet ids from the connection table
    conflict_subnets = []
    parent_subnets_providers.each do |subnet|
      begin
        remote_route_table = aws_compute_agent.associate_route_table route_table.id, subnet.provider_id
      rescue Fog::Compute::AWS::Error => error
        e = error.message.split('=>')
        conflict_subnets.push(subnet.provider_id) if e.present? && e[0].strip.eql?('AlreadyAssociated')
        self.error_message = error.message
      end
    end
    self.association_conflict = conflict_subnets
    self.data_will_change!
    self.save!
    create_tag if get_associated_environments.size < 2
    raise Fog::Compute::AWS::Error, self.error_message unless conflict_subnets.empty?
    update_from_remote_service(aws_compute_agent.route_tables.get(route_table.id))
  end

  def save_ig_routes(route_table)
    get_additional_ig_routes.each do |additional_route|
      instance_route = get_route_ig_params(additional_route)
      additional_route = route_table_wrapper.create_ig_route(route_table.id, instance_route[:destination_cidr_block], instance_route[:internet_gateway_id])
      CloudStreet.log "----------------------created additional_route ig-----------#{additional_route.inspect}"
    end
  end

  def disassoc_subnet(subnet_id)
    route_tables = aws_compute_agent.route_tables.all("vpc-id" => vpc.vpc_id, "association.subnet-id" => subnet_id)
    associations = {}
    associations = route_tables.first.associations.select { |assoc| assoc['subnetId'].eql?(subnet_id) }
    puts "associations=#{associations}"
    route_table_wrapper.detach_subnet(associations[0]['routeTableAssociationId'])
  end

  def get_additional_ig_routes
    additional_route_properties.each do |property|
      next if property && (property != 'internet_gateway')
      property["internet_gateway_id"] = self.vpc.internet_gateway.provider_id rescue ''
    end
    additional_route_properties.reject{|route| route['connected_service'] != 'internet_gateway'}
  end

  def get_additional_server_routes
    additional_route_properties.each do |property|
      next if property && property.eql?('internet_gateway')
      server = self.environment.services.instance_servers.where(id: property['connected_service_id']).first
      if server
        property['instance_id'] = server.provider_id rescue ''
        property['network_interface_id'] = server.provider_data['network_interfaces'][0]['networkInterfaceId'] rescue ''
      end
    end
    additional_route_properties.reject{|route| route['connected_service'] == 'internet_gateway'}
  end


  def additional_route_properties
    if self.additional_properties && self.additional_properties["properties"]
      self.additional_properties["properties"].last["value"].reject { |hash| hash["origin"] == "CreateRouteTable" }
    elsif self.routes
      self.routes.reject { |hash| hash["origin"] == "CreateRouteTable" }
    else
      []
    end

  end

  def get_route_ig_params(options)
    {
      destination_cidr_block: options["destinationCidrBlock"],
      internet_gateway_id: self.vpc.get_ig_provider_id
    }
  end

  def get_route_instance_params(options)
    {
      destination_cidr_block: options["destinationCidrBlock"],
      instance_id: options["instance_id"],
      network_interface_id: options["network_interface_id"]
    }
  end

  def route_table_attrs
    rt_attrs = {
      vpc_id: provider_vpc_id
    }
    CloudStreet.log "----------------------------------------------route_table_attrs=#{rt_attrs.inspect}"
    rt_attrs
  end
 
  def save_route_table_from_aws
    if route_table_id
      remote_rt = aws_compute_agent.route_tables.get(route_table_id)
    else
      rt_service_vpc_id = environment.services.vpcs.first.provider_id
      remote_rt = aws_compute_agent.route_tables.all('vpc-id' => rt_service_vpc_id).first
    end
    name_tag = remote_rt.nil? ? 'main' : (remote_rt.tags['Name'] || 'main')
    tags_map = { Name: name_tag }
    aws_compute_agent.create_tags((route_table_id || remote_rt.id), tags_map)
    update_from_remote_service(remote_rt)
    remote_rt
  end

  def update_from_remote_service(remote_service)
    # Update service table
    self.route_table_id = remote_service.id
    self.routes = get_parsed_routes(remote_service)
    self.provider_id = remote_service.id
    self.provider_data  = ProviderWrappers::AWS.parse_remote_service(remote_service)
    self.associations = remote_service.associations
    self.tags = remote_service.tags
    self.name = remote_service.tags['Name'] || 'main'
    self.save

    # Update route_table table too with new response
    update_route_table_table(provider_id, remote_service) if is_main?
  end

  def get_parsed_routes(remote_service)
    remote_routes = remote_service.routes
    return remote_routes if is_main?
    return {} unless remote_routes
    parsed_rt_routes = remote_routes.collect do |rt_hash|
      if rt_hash.has_key?('gatewayId') && rt_hash['gatewayId'] && rt_hash['gatewayId'].match(/^igw-/)
        #has IG route
        env_ig = self.environment.services.internet_gateways.first
        cidr = rt_hash['destinationCidrBlock']
        {"destinationCidrBlock"=>cidr, "connected_service"=>"internet_gateway", "connected_service_name"=>"internet_gateway", "connected_service_id"=>env_ig.id}

      elsif rt_hash.has_key?('instanceId') && rt_hash['instanceId'] && rt_hash['instanceId'].match(/^i-/)
        #has Server
        env_server = self.environment.services.instance_servers.where(provider_id: rt_hash['instanceId']).first
        {"destinationCidrBlock"=>rt_hash['destinationCidrBlock'], "connected_service"=>"", "connected_service_name"=>env_server.name, "connected_service_id"=>env_server.id, "instance_id"=>rt_hash['instanceId'], "network_interface_id"=>rt_hash['networkInterfaceId']}
      else
        rt_hash
      end
    end
  end

  def update_route_table_table(provider_id, route_table)
    route_table_old = ::RouteTable.where(provider_id: provider_id).last
    route_table_old = vpc.route_table
    route_table_old.update(
      routes:         route_table.routes || [],
      provider_id:    route_table.id,
      name:           route_table.tags['Name'] || 'main',
      associations:   route_table.associations || [],
      provider_data:  ProviderWrappers::AWS.parse_remote_service(route_table)
    )
  end


  def update_vpc_and_depencies(vpc)
    vpc_route_table = vpc.route_table
    update_default_routetable_service(vpc_route_table)
  end

  def update_default_routetable_service(vpc_route_table)
    self.attributes = {
      routes:  vpc_route_table.routes,
      provider_id:  vpc_route_table.provider_id,
      provider_data:  vpc_route_table.provider_data,
      associations:  vpc_route_table.associations,
      tags:  vpc_route_table.tags,
      name:  vpc_route_table.tags['Name'] || 'main'
    }
    # additional_properties['name'] = attributes['name']
    # additional_properties_will_change!
    save!
  end

  def update_service(options)
    allowed_update_actions = [:attach_subnet, :detach_subnet, :create_route, :delete_route, :replace_route, :edit_name, :resolve_association]
    action = options[:update_action].to_sym
    send action, options
    self.routes = get_parsed_routes(get_remote_service)
    self.save
    true
  end

  def attach_subnet(options)
    begin
      subnets_provider_id = options[:subnets_provider_id]
      subnet = environment.services.subnets.where(provider_id: subnets_provider_id).first
      detach_attached_rt(subnet)
      route_table_wrapper.attach_subnet(provider_id, subnets_provider_id)
      update_provider_data_from_provider(changed_fields: [:associations])
      Interface.find_or_create_interfaces(self, subnet)
    rescue Fog::Compute::AWS::Error => error
      e = error.message.split('=>')
      if e.present? && e[0].strip.eql?('AlreadyAssociated')
        self.association_conflict = [subnets_provider_id] if self.association_conflict.nil? || self.association_conflict.empty?
        self.association_conflict.push(subnets_provider_id) if self.association_conflict.present? && !self.association_conflict.include?(subnets_provider_id)
        self.data_will_change!
        self.save!
      end
      raise error
    end
  end

  def detach_attached_rt(subnet)
    assoc_rt = subnet.fetch_child_services(type).first
    return if assoc_rt.nil?
    CloudStreet.log "----detaching------#{assoc_rt.provider_id}-----with-----#{subnet.provider_id}"
    detach_assoc_subnet(Hash[:subnets_provider_id, subnet.provider_id], assoc_rt)
  end

  def detach_assoc_subnet(options, assoc_rt)
    subnets_provider_id = options[:subnets_provider_id]
    subnet = environment.services.subnets.where(provider_id: subnets_provider_id).first
    association_id = assoc_rt.provider_data_associations.find_association_id_by_subnet(subnets_provider_id)
    return if association_id.nil?
    route_table_wrapper.detach_subnet(association_id)
    assoc_rt.update_provider_data_from_provider(changed_fields: [:associations])
    Interface.find_and_delete_connections(assoc_rt, subnet)
  end

  def edit_name(options)
    name = options[:service_attribute][:name]
    tags_map = { Name: name }.merge(env_n_app_tags)
    begin
      route_table_wrapper.create_tags(provider_id, tags_map)
      update_from_remote_service(aws_compute_agent.route_tables.get(provider_id))
    rescue Fog::Compute::AWS::NotFound => e
      CloudStreet.log "#{e.message}"
      self.error!
    end
  end

  def resolve_association(options)
    subnets_provider_id = options[:subnets_provider_id]
    subnets = environment.services.subnets.where(provider_id: subnets_provider_id)
    subnets.each do |subnet|
      begin
        attach_subnet(subnets_provider_id: subnet.provider_id)
      rescue Fog::Compute::AWS::Error => error
        e = error.message.split('=>')
        if e.present? && e[0].strip.eql?('AlreadyAssociated')
          disassoc_subnet(subnet.provider_id)
          attach_subnet(subnets_provider_id: subnet.provider_id)
        end
      end
    end
    attrs = { association_conflict: [], state: 'running', error_message: '' }
    self.update_attributes attrs
  end

  def detach_subnet(options)
    subnets_provider_id = options[:subnets_provider_id]
    subnet = environment.services.subnets.where(provider_id: subnets_provider_id).first
    association_id = provider_data_associations.find_association_id_by_subnet(subnets_provider_id)
    route_table_wrapper.detach_subnet(association_id)
    update_provider_data_from_provider(changed_fields: [:associations])
    Interface.find_and_delete_connections(self, subnet)
  end

  def create_route(options)
    route_table_wrapper.create_route(provider_id, options[:destination_cidr_block], options[:internet_gateway_id], options[:instance_id], options[:network_interface_id])
    update_provider_data_from_provider(changed_fields: [:routes])
    if options[:instance_id] && options[:instance_id].match(/^i-\S+/)
      associated_instance = self.environment.services.instance_servers.find_by_provider_id(options[:instance_id])
      Interface.find_or_create_interfaces(self, associated_instance) if associated_instance
    end
  end

  def delete_route(options)
    route_table_wrapper.delete_route(provider_id, options[:destination_cidr_block])
    update_provider_data_from_provider(changed_fields: [:routes])
  end

  def replace_route(options)
    route_table_wrapper.replace_route(provider_id, options[:destination_cidr_block], options)
    update_provider_data_from_provider(changed_fields: [:routes])
  end

  def provider_data_associations(force_update: false)
    return @provider_data_associations if !force_update && @provider_data_associations.present?

    raw_assoc = self.parsed_provider_data["associations"] if provider_data.present?
    @provider_data_associations = ::RtAssociations.new(raw_assoc)

  end

  def route_table_wrapper
    ProviderWrappers::AWS::Networks::RouteTable.new(service: self, agent: aws_compute_agent)
  end

  def parent_services
    [Services::Vpc, Services::Network::AvailabilityZone, Services::Network::SecurityGroup::AWS, Services::Network::Subnet::AWS, Services::Compute::Server::AWS]
  end

  # custom validations

  def can_attach_subnet(options)
    # return main_rt_update_error if is_main? #association of main rt can be modified
    { error: false }
  end

  def can_resolve_association(options)
    subnets_provider_id = options[:subnets_provider_id]
    subnet = environment.services.subnets.where(provider_id: subnets_provider_id).first
    return { error: true, err_msg: :subnet_not_available } unless subnet.present?
    { error: false }
  end

  def can_detach_subnet(options)
    # return main_rt_update_error if is_main? #association of main rt can be modified

    subnets_provider_id = options[:subnets_provider_id]
    association_id = provider_data_associations(force_update: true).find_association_id_by_subnet(subnets_provider_id)
    return { error: true, err_msg: :is_not_attahced } if association_id.blank?

    { error: false }
  end

  def can_create_route(options)
    return main_rt_update_error if is_main?
    { error: false }
  end

  def can_delete_route(options)
    return main_rt_update_error if is_main?
    { error: false }
  end

  def can_replace_route(options)
    return main_rt_update_error if is_main?
    { error: false }
  end

  def can_edit_name(options)
    { error: false }
  end

  def check_service_specific_status
    { error: false }
  end

  def main_rt_update_error
    { error: true, err_msg: :action_not_supported } # we cannot modify the main RT from service class interface
  end

  def is_main?
    main
  end

  def get_associated_environments
    route_tables = Services::Network::RouteTable::AWS.select('environments.id', 'environments.name').where(vpc_id: self.vpc_id).where("services.data ->> 'route_table_id' = ?", self.provider_id).where("environments.state != 'terminated'").joins(:environment)
    route_tables.to_a.uniq { |env| env.id }
  end

  def self.create_in_local(compute, service)
    vpc_id = ::Vpc.where(
      :vpc_id=>service[:vpc_id],
      :adapter_id=>service[:adapter_id],
      :region_id=>service[:region_id]
    ).pluck(:id).first
    if service[:main]
      ::RouteTable.create!({
                             account_id: service[:account_id],
                             region_id: service[:region_id],
                             adapter_id: service[:adapter_id],
                             provider_id: service[:provider_id],
                             provider_data: service[:provider_data],
                             routes: service[:provider_data]["routes"],
                             associations: service[:provider_data]["associations"],
                             name: service[:name],
                             type: "RouteTables::AWS",
                             vpc_id: vpc_id
      })
    else
      self.create(
        name: service[:name],
        state: 'running',
        main: false,
        route_table_id: service[:provider_id],
        routes: service[:provider_data]["routes"],
        associations: service[:provider_data]["associations"],
        tags: service[:provider_data]["tags"],
        type: self.to_s,
        provider_type: 'Providers::AWS',
        account_id: service[:account_id],
        region_id: service[:region_id],
        adapter_id: service[:adapter_id],
        geometry: {},
        provider_data: service[:provider_data],
        generic: false,
        generic_type: self.parent.to_s,
        desired_state: 'running',
        provider_id: service[:provider_id],
        vpc_id: vpc_id
      )
    end
  end

  def self.create_on_remote(compute, service)
    #create on remote
    route_table = compute.route_tables.create({
                                                id: service[:provider_id],
                                                vpc_id: service[:vpc_id],
                                                routes: service[:routes],
                                                associations: service[:associations],
                                                tags: service[:tags]
    })

    #update dependancies in local
    RouteTable.where(provider_id: service[:provider_id]).
    update_all({
                 provider_id: route_table.id,
                 provider_data: ProviderWrappers::AWS.parse_remote_service(route_table),
                 routes: route_table.routes,
                 associations: route_table.associations
    })
    Service.where(provider_id: service[:provider_id],generic_type: 'Services::Network::RouteTable').
    each do|service|
      service.provider_id = route_table.id
      service.routes = route_table.routes
      service.associations = route_table.associations
      service.save
    end
    # TODO service_vpc_id: ?
  end

  #Method : to find the diff of the remote services & the local services
  def self.diff_remote_services(adapter,compute, region)
    remote_services = compute.route_tables.map(&method(:remote_service_attrs)).compact
    local_services =
    Service.where({
                    adapter_id: adapter.id,
                    generic_type: superclass.to_s,
                    region_id: region.id,
                    state: 'running'
    }).
      where.not("data ->> 'main' = 'true'").
      where.not(vpc_id: nil).
      map(&method(:service_attrs))

    default_local_services =
      ::RouteTable.where({adapter_id: adapter.id,region_id: region.id}).
      map(&method(:default_service_attrs))

    local_services += default_local_services
    Synchronizer.compare(remote_services,local_services)
  end

  def self.service_attrs(local_service)
    {
      object: local_service,
      provider_id: local_service.provider_id,
      generic_type: local_service.generic_type,
      local: true,
      provider_data: local_service.provider_data,
      main: local_service.is_main?,
      name: local_service.name,
      tags: local_service.tags,
      vpc_id: local_service.vpc.vpc_id,
      routes: local_service.routes,
      associations: local_service.associations
    }
  end

  def self.default_service_attrs(local_service)
    {
      object: local_service,
      provider_id: local_service.provider_id,
      generic_type: 'RouteTables::AWS',
      local: true,
      provider_data: local_service.provider_data,
      main: true,
      name: local_service.name,
      tags: local_service.provider_data["tags"],
      vpc_id: local_service.provider_data["vpc_id"],
      routes: local_service.routes,
      associations: local_service.associations
    }
  end

  def self.remote_service_attrs(remote_service)
    return nil unless remote_service.vpc_id
    main = (remote_service.associations.empty? ? false : remote_service.associations.any?{
              |association| association["main"]==true
    })
    {
      provider_id: remote_service.id,
      generic_type: superclass.to_s,
      remote: true,
      provider_data: JSON.parse(remote_service.to_json),
      main: main,
      name: remote_service.tags["Name"]||remote_service.id,
      tags: remote_service.tags,
      vpc_id: remote_service.vpc_id,
      routes: remote_service.routes,
      associations: remote_service.associations
    }
  end

  def validate_for_termination
    errors.add(:dependent_service, I18n.t('termination_validation.error_msgs.route_table.dependent_service_present')) if associations.present?
    errors.add(:main_routetable, I18n.t('termination_validation.error_msgs.route_table.is_main')) if is_main?
  end

  def terminate_service(params={})
    #NOTE : Do not delete main RouteTable
    # raise "cannot delete main route table"
    unless is_main?
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

  def get_routes_cidr_block
    self.routes
  end

  def find_or_create_interface_connections(&services_context)
    return unless is_created_and_not_in_error?
    services_context.call.vpcs.each do |vpc|
      Interface.find_or_create_interfaces(self, vpc)
    end

    #check connection with ig required interface connections?
    internet_gateway = services_context.call.internet_gateways.find{|ig| ig.is_synced_service?}
    Interface.find_or_create_interfaces(internet_gateway,self) if internet_gateway

    self.associations.each do |association|
      subnet_id = association["subnetId"]
      if subnet_id.present?
        services_context.call.subnets.where(provider_id: subnet_id).each do |synced_subnet|
          Interface.find_or_create_interfaces(self,synced_subnet)
        end
      end
    end
    self.routes = self.routes.collect do|route|
      if route.has_key?("instance_id")
        instance = services_context.call.instance_servers.where(provider_id: route["instance_id"]).first
        if instance.present?
          route["connected_service"]=instance.private_ip_address
          route["connected_service_id"] = instance.id
          route["instance_id"] = route["instance_id"]
          route["connected_service_name"] = instance.name
        end
      end
      route
    end
    self.data_will_change!
    self.save!
  end

  def reload_service(aws_service, user)
    default_rt = RouteTables::AWS.where(account: account, region: region, adapter: adapter).find_by_provider_id(aws_service.id)
    if default_rt.present?
      attributes = RouteTables::AWS.format_attributes_by_raw_data(aws_service).merge(provider_data: ProviderWrappers::AWS.parse_remote_service(aws_service))
      default_rt.update(attributes)
    end
    super(aws_service, user)
    self.save!
  end

  def reload_associations(service, aws_service, user)
    subnets_provider_ids = get_subnet_associations
    aws_associations = aws_service.associations

    options = Hash.new
    if aws_associations.present?
      aws_associations.each do |association|
        # puts "sub for #{association["subnetId"]} : #{environment.services.subnets.where(provider_id: association["subnetId"]).first}"
        subnet = environment.services.subnets.where(provider_id: association["subnetId"]).first
        if subnet.present?
          options.merge!({subnets_provider_id: subnet.provider_id})
          puts "attaching subnet : #{association["subnetId"]}"
          self.attach_subnet(options)
        else
          puts "not doing anything for #{association["subnetId"]}"
        end
        subnets_provider_ids = subnets_provider_ids - [association["subnetId"]]
      end
    end
    if subnets_provider_ids.present?
      subnets_provider_ids.each do |subnet_provider_id|
        subnet = environment.services.subnets.where(provider_id: subnet_provider_id).first
        # puts "detaching subnet : #{association["subnetId"]} from local"
        update_provider_data_from_provider(changed_fields: [:associations])
        Interface.find_and_delete_connections(self, subnet)
      end
    end

  end

  def get_subnet_associations
    subnets_provider_ids = []
    subnet_interface = interfaces.where(interface_type: 'Protocols::Subnet').first
    if subnet_interface
      subnet_interface.remote_interfaces.collect do |i|
        subnet = i.service
        subnets_provider_ids << subnet.provider_id
      end
    else
      []
    end
    subnets_provider_ids
  end

  def cidrs_in_routes
    (routes || []).map { |route_map| route_map['destinationCidrBlock'] }
  end

  def cidr_of_local_route
    routes.find { |route_map| route_map['gatewayId'] == 'local' }['destinationCidrBlock'] rescue nil
  end

  class << self
    def format_attributes_by_raw_data(aws_service)
      {
        main: (aws_service.associations.empty? ? false : aws_service.associations.any?{|association|
                 association["main"]==true
        }),
        route_table_id: aws_service.id,
        state: "running",
        name: aws_service.tags["Name"]||aws_service.id,
        associations: aws_service.associations,
        routes: cast_routes(aws_service.routes),
        tags: aws_service.tags,
        service_tags: Services::ServiceHelpers::AWS.get_service_tags(aws_service.tags)
      }.merge(super)
    end

    def cast_routes(routes)
      routes.collect do|route|
        if route["instanceId"].present?
          {
            connected_service: nil,
            connected_service_id: nil,
            instance_id: route["instanceId"],
            connected_service_name: nil,
            destinationCidrBlock: route["destinationCidrBlock"]
          }
        else
          route
        end
      end
    end

    def update_routes_from_remote(rt, remote_rt)
      self.where(adapter_id: rt.adapter_id, provider_id: rt.provider_id).each do |rt_service|
        rt_service.routes = remote_rt.routes
        rt_service.provider_data = ProviderWrappers::AWS.parse_remote_service(remote_rt)
        rt_service.save
      end
    end
  end

  def svg_image_string
    vpc = fetch_remote_services(Protocols::Vpc).first
    vpc_abs_geo = vpc.find_free_space
    rt_img_x = (vpc_abs_geo['x'].to_i + 10)
    rt_img_y = (vpc_abs_geo['y'].to_i + 10)
    update_geo_for_new_service!(rt_img_x, rt_img_y)

    <<-RT_STR
    <image xmlns="http://www.w3.org/2000/svg" x="#{rt_img_x}" y="#{rt_img_y}" width="56" height="56" xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="http://#{get_hostname}/assets/services/network/routetable.svg" pointer-events="none"/>
      <g xmlns="http://www.w3.org/2000/svg" transform="translate(#{rt_img_x + 2},#{rt_img_y + 58})"><switch><foreignObject pointer-events="all" class="foreignobject" width="52" height="11" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility"><div xmlns="http://www.w3.org/1999/xhtml" style="display: inline-block; font-size: 12px; font-family: Verdana; color: rgb(176, 176, 176); line-height: 14px; vertical-align: top; overflow: hidden; max-height: 52px; width: 52px; white-space: normal; text-align: center;">#{name}</div></foreignObject><text x="26" y="6" fill="#B0B0B0" text-anchor="middle" font-size="12px" font-family="Verdana">[Object]</text></switch></g></g></svg>
                                                               RT_STR
                                                               end

                                                               private

                                                               def set_parent_container_id
                                                                 fetch_first_remote_service("Protocols::Vpc").id if fetch_first_remote_service("Protocols::Vpc")
                                                               end

                                                               def parent_service
                                                                 self.interfaces.of_type(Protocols::Vpc).first.remote_interfaces.first.service rescue nil
                                                               end
                                                               end
