class Services::Network::LoadBalancer::AWS < Services::Network::LoadBalancer
  include Services::ServiceHelpers::AWS
  include Behaviors::Costable::Amazon::LoadBalancer
  store_accessor :data, :region, :dns_name, :scheme, :connection_timeout, :category, :listeners, :connection_draining, :connection_draining_timeout, :cross_zone_load_balancing, :ssl_certificate, :new_ssl_certificate, :ping_protocol, :ping_protocol_port, :ping_path, :tags, :availability_zones, :instance_health # health check attributes

  UPDATABLE_ATTRS = [:healthy_threshold, :hcheck_interval, :ping_protocol, :ping_protocol_port, :ping_path, :unhealthy_threshold, :response_timeout, :listeners, :connection_timeout, :cross_zone_load_balancing, :ssl_certificate ]
  AWS_RECORD_SCOPE_METHOD = :load_balancers

  SCHEME_OPTIONS = %w(internal internet-facing)
  PING_PROTOCOL_OPTIONS = %w(HTTP TCP HTTPS SSL)
  VALID_SECURE_PROTOCOLS = ['HTTPS', 'SSL']
  INTERFACES = [Services::Vpc, Services::Network::Subnet::AWS,  Services::Network::SecurityGroup::AWS, Services::Compute::Server::AWS ]

  def set_default_addtional_data
    { "tags" => {} }
  end

  def connected_to(service, via_services_map)
    if interfaces_includes?(service)
      case service.class.to_s
      when Services::Vpc.to_s
        return is_connected_to_vpc?(service)
      when Services::Network::SecurityGroup::AWS.to_s
        return is_connected_to_security_group?(service)
      when Services::Network::Subnet::AWS.to_s
        return is_connected_to_subnet?(service)
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

  def is_connected_to_security_group?(service)
    if self.provider_data.blank?
      self.connected_via_interface_to(service)
    else
      return (self.parsed_provider_data["security_groups"]||[]).include?(service.provider_id)
    end
  end

  def is_connected_to_subnet?(service)
    if self.provider_data.blank?
      self.connected_via_interface_to(service)
    else
      return self.parsed_provider_data["subnet_ids"].include?(service.provider_id)
    end
  end

  def is_connected_to_server?(service)
    if self.provider_data.blank?
      self.connected_via_interface_to(service)
    else
      self.provider_data["instances"] && self.provider_data["instances"].include?(service.provider_id)
    end
  end

  def provision
    return if is_present_on_provider?
    CloudStreet.log "--------------------Creating #{self.class.name} #{self.inspect}"
    self.name = update_application_variables(self.name, @user)

    load_balancer_attrs = {
      id: name,
      scheme: scheme,
      subnet_ids: parent_subnets_provider_ids,
      security_groups: provider_security_group_ids || []
      # Why this attribute(listener) is treated different by taking string?
      # https://github.com/fog/fog/issues/431
    }

    new_listeners = []
    self.listeners.each do |listener|
      listener = listener.to_h
      protocol = listener['Listener']['protocol']
      instance_protocol = listener['Listener']['instance_protocol']
      if !listener['Listener']['new_ssl_certificate'].blank?
        listener['Listener']['ssl_certificate'] = create_new_ssl_certificate(listener['Listener']['new_ssl_certificate'])
      end
      if ((protocol.eql?("HTTPS")|| protocol.eql?("SSL")) || (instance_protocol.eql?("HTTPS")||instance_protocol.eql?("SSL")) )
        listener['Listener'].merge!('SSLCertificateId' => listener['Listener']['ssl_certificate']['Arn'])
      end
      new_listeners << listener
    end

    # ===================
    # if self.new_ssl_certificate.present?
    #   self.ssl_certificate = create_new_ssl_certificate(self.new_ssl_certificate)
    # end

    # puts "ssl_certificate : #{self.ssl_certificate}"

    # CloudStreet.log "---------------------listeners : #{listeners}"

    # listeners.each do |listener|
    #   protocol = listener['Listener']['protocol']
    #   instance_protocol = listener['Listener']['instance_protocol']
    #   if ((protocol.eql?("HTTPS")|| protocol.eql?("SSL")) || (instance_protocol.eql?("HTTPS")||instance_protocol.eql?("SSL")) )
    #       listener['Listener'].merge!('SSLCertificateId' => self.ssl_certificate['Arn'])
    #   end
    # end
    # ===================


    CloudStreet.log "---------------------listeners after certificate : #{listeners}"

    load_balancer_attrs.merge!('ListenerDescriptions' => new_listeners)
    self.listeners = new_listeners
    # 'ListenerDescriptions' => ['Listener' => {'InstancePort' => 8080, 'InstanceProtocol' => 'TCP', 'LoadBalancerPort' => 8080, 'Protocol'=> 'TCP', 'SSLCertificateId' => 'ARN of the server certificate'}]
    begin
      retries ||= 0
      lb = aws_elb_agent.load_balancers.create(load_balancer_attrs)
    rescue Fog::AWS::IAM::NotFound => e
      if (retries += 1) < 3
        print "."
        sleep 5
        retry
      end
    end
    wait_till_ready lb

    # some attributes cannot be set at the time of creation, so setting them after creating LB
    remaining_attr_map = {}
    remaining_attr_map.merge!({ 'ConnectionSettings'     => { 'IdleTimeout' => connection_timeout } })        if connection_timeout.present?
    remaining_attr_map.merge!({ 'CrossZoneLoadBalancing' => { 'Enabled'     => cross_zone_load_balancing } }) unless cross_zone_load_balancing.nil?
    remaining_attr_map.merge!({ 'ConnectionDraining'     => { 'Enabled' => connection_draining, 'Timeout' => connection_draining_timeout } }) unless connection_draining.nil?
    CloudStreet.log "--------------------remaining_attr_map=#{remaining_attr_map.inspect}"
    aws_elb_agent.modify_load_balancer_attributes(lb.id, remaining_attr_map) if remaining_attr_map.present?

    aws_elb_agent.add_tags lb.id, lb_env_n_app_tags

    health_check_attributes = get_health_check_attributes
    CloudStreet.log "--------------------health_check_attrs=#{health_check_attributes}"
    aws_elb_agent.configure_health_check(load_balancer_attrs[:id],health_check_attributes)

    self.region   = lb.availability_zones[0]
    self.dns_name = lb.dns_name
    self.save!
    save_provider_data! lb.to_json, lb.id
    update_attribute :service_vpc_id, fetch_first_remote_service(Protocols::Vpc).id

    CloudStreet.log "--------------------created #{lb.inspect}"
  end

  def create_new_ssl_certificate(new_ssl_certificate)
    additional_data = new_ssl_certificate["certificate_chain"].present? ? {"CertificateChain" => new_ssl_certificate['certificate_chain'] } : {}

    CloudStreet.log "---------------------Additional_data : #{additional_data}"
    certificate = ProviderWrappers::AWS::Iam.new(service: self, agent: aws_iam_agent_no_region).create_server_certificate(new_ssl_certificate['public_key_certificate'],new_ssl_certificate['private_key'],new_ssl_certificate['certificate_name'],additional_data)
    sleep 4.5 # to allow certificate to create on AWS and use that to cerate LB @ load_balancers.create
    CloudStreet.log "---------------------Certificate created : #{certificate}"
    certificate
  end

  def lb_env_n_app_tags
    { Name: name}#, environment_id: environment.id
  end

  def move_synced_service_into_env(env)
    begin
      self.reload
      assign_env_tags
      #create_tag
    rescue => e
      CloudStreet.log e.message
      CloudStreet.log e.backtrace
    end
  end

  def connection_up(remote_service)
    return unless remote_service.type == 'Services::Compute::Server::AWS'
    CloudStreet.log "--------------------connecting #{remote_service.inspect} with #{self.class.name}"
    aws = aws_elb_agent

    CloudStreet.log "=====================remote_service.provider_id=#{remote_service.provider_id.inspect}"
    lb = aws.load_balancers.get(self.provider_id)
    return unless lb

    CloudStreet.log "====================lb=#{lb.inspect}"
    lb.register_instances(remote_service.provider_id)
    lb.reload
    set_instance_health(lb, "Instance registration is still in progress.")
    save_provider_data! lb.to_json, lb.id
    CloudStreet.log "--------------------connected #{lb.inspect}"
  end

  def connection_down(service)
    CloudStreet.log "  [+] ConnectionDown()"
    CloudStreet.log "      service_name: #{service.name}"

  rescue Fog::AWS::ELB::InvalidInstance
    CloudStreet.log "Couldn't find instance id, assuming that's all good!"
    return
  end

  def terminate_service(params={})
    wrapper_agent.destroy
    CloudStreet.log "-------------------------------------Terminated(#{self.type}) => #{self.name}"
  end

  def get_health_check_attributes
    {
      "HealthyThreshold"   => healthy_threshold,
      "Interval"           => hcheck_interval,
      "Target"             => get_target,
      "Timeout"            => response_timeout,
      "UnhealthyThreshold" => unhealthy_threshold
    }
  end

  def get_az_names
    parent_subnets_providers.map { |subnet_service| subnet_service.fetch_availability_zone_name }.uniq.compact
  end

  def get_load_balancer
    aws_elb_agent.load_balancers.get(provider_id)
  end
  alias_method :get_remote_service, :get_load_balancer

  def connection_update
    CloudStreet.log "  [+] ConnectionUpdate()"
  end

  def connection_broken
    CloudStreet.log "  [+] ConnectionBroken()"
  end

  def shutdown
    # CloudStreet.log "  [+] DeleteLoadBalancer(#{self.provider_id})"

    # aws = adapter.connection_elb

    # id = self.provider_id

    # if id
    #   elb = aws.load_balancers.get(id)

    #   return unless elb

    #   elb.destroy

    #   # elb.wait_for do
    #   #   print "."
    #   #   #elb.state == "terminated"
    #   #   aws.load_balancers.get(id)
    #   # end
    # end
  end

  def update_service(params)

    if self.provider_id

      load_balancer = wrapper_agent.get

      if params[:service_attribute].keys.include?("healthy_threshold")
        configure_health_check_on_provider(params[:service_attribute])
      end

      if params[:service_attribute].keys.include?("connection_timeout")
        configure_basic_properties_on_provider(params[:service_attribute])
      end

      if params[:service_attribute].keys.include?("listeners")
        configure_listeners_on_provider(params[:service_attribute])

        if(self.state == "error")
          self.start!
          self.started!
        end
      end

      params[:service_attribute].merge!(provider_data: ProviderWrappers::AWS.parse_remote_service(load_balancer))
    end

    update(params[:service_attribute])
  end

  def check_service_specific_status
    if self.stopped?
      service = {:status_msg => "already_stopped", :response => self, :error => true}
      return service
    end

    return service = {"error" => false}
  end

  def check_service_state
    if !self.can_stop?
      CloudStreet.log "Unable to transition service from current #{self.state} to stopped"
      return false
    end
    return true
  end

  def create_tag_on_provider(tag_map)
    ProviderWrappers::AWS::TagRemote.new(service: self, agent: aws_elb_agent).create(tag_map)
  end


  def properties
    certificate = get_available_certificate
    super + [
      {
        form_options: {
          type: "hidden",
          readonly: "readonly"
        },
        name: "dns_name",
        title: "DNS Name",
        value: dns_name
      },
      {
        name: "scheme",
        title: "Scheme",
        form_options: {
          type: "select",
          options: SCHEME_OPTIONS
        },
        value: scheme || SCHEME_OPTIONS.first
      },
      {
        form_options: {
          type: "select",
          options: PING_PROTOCOL_OPTIONS,
          depends_on: true
        },
        name: "ping_protocol",
        title: "Ping Protocol",
        value: ping_protocol || PING_PROTOCOL_OPTIONS.first
      },
      {
        form_options: {
          type: "text"
        },
        name: "ping_protocol_port",
        title: "Ping Port",
        value: "80"
      },
      {
        form_options: {
          type: "text",
          depends_on: true
        },
        name: "ping_path",
        title: "Ping Path",
        value: "index.html"
      },
      {
        form_options: {
          type: "lblistner"
        },
        name: "listeners",
        title: "listeners",
        value: get_listeners(certificate) || [{'Listener' => {'instance_port' => 80, 'instance_protocol' => 'HTTP', 'lb_port' => 80, 'protocol' => 'HTTP'}}]
      },
      {
        form_options: {
          type: "checkbox"
        },
        name: "cross_zone_load_balancing",
        title: "Cross Zone",
        value: cross_zone_load_balancing || false
      },
      {
        form_options: {
          type: "checkbox"
        },
        name: "connection_draining",
        title: "Connection Draining",
        value: connection_draining || false
      },
      {
        form_options: {
          type: "text",
          unitLabel: "seconds",
          depends_on: false
        },
        name: "connection_draining_timeout",
        title: "Connection Draining Timeout",
        value: connection_draining_timeout || 60,
        validation: '/^[0-9]*$/'
      },
      {
        form_options: {
          type: "text",
          unitLabel: "seconds"
        },
        name: "connection_timeout",
        title: "Idle Connection Timeout",
        value: "300",
        validation: '/^[0-9]*$/'
      },
      {
        name: "ssl_certificate",
        title: "SSL Certificate",
        form_options: {
          type: "select",
          options: certificate,
          data: certificate
        },
        value: certificate ? certificate[0] : []
      },
      {
        name: "new_ssl_certificate",
        title: "New SSL Certificate",
        form_options: {
          type: "text",
          depends_on: false
        },
        value: get_new_ssl_certificate
      }
    ]
  end

  def certificate_already_exist?(certificates, certificate_name)
    certificates = get_available_certificate if certificates.blank?
    certificates.detect { |certificate| certificate["ServerCertificateName"] == certificate_name }
  end

  def get_new_ssl_certificate
    self.new_ssl_certificate
  end

  def get_available_certificate
    certificates = ProviderWrappers::AWS::Iam.new(service: self, agent: aws_iam_agent_no_region).fetch_server_certificates
  rescue Exception => e
    CloudStreet.log("#{e.class} : #{e.message} : #{e.backtrace}")
    []
  end

  def parent_services
    [Services::Vpc, Services::Network::SecurityGroup::AWS, Services::Network::Subnet::AWS, Services::Network::SubnetGroup::AWS]
  end

  def attach_subnets(subnets)
    subnet_ids = subnets.pluck :provider_id
    wrapper_agent.attach_subnets(subnet_ids: subnet_ids) if self.provider_id
    subnets.each do |subnet| Interface.find_or_create_interfaces(self,subnet) end
    self.provider_data = ProviderWrappers::AWS.parse_remote_service(wrapper_agent.get)
    self.save
    rescue Fog::AWS::ELB::InvalidConfigurationRequest => e
      CloudStreet.log("#{e.message}")
      []
  end

  def detach_subnets(subnets)
    subnet_ids = subnets.map(&:provider_id)
    wrapper_agent.detach_subnets(subnet_ids: subnet_ids) if self.provider_id
    self.environment.services.subnets.where(provider_id: subnet_ids).each do |subnet|
      Interface.find_and_delete_connections(self,subnet)
    end
    self.provider_data = ProviderWrappers::AWS.parse_remote_service(wrapper_agent.get)
    self.save
  end

  def apply_security_groups(security_groups)
    security_group_ids = security_groups.map(&:group_id)
    wrapper_agent.apply_security_groups(security_group_ids: security_group_ids) if self.provider_id
    sg_interface = self.interfaces.where(interface_type: "Protocols::SecurityGroup").first
    if sg_interface
      sg_interface.remote_interfaces.each do |remote_interface|
        security_group = remote_interface.service
        Interface.find_and_delete_connections(self,security_group)
      end
    end
    self.environment.services.security_groups.where(provider_id: security_group_ids).each do |security_group|
      Interface.find_or_create_interfaces(self,security_group)
    end
    self.provider_data = ProviderWrappers::AWS.parse_remote_service(wrapper_agent.get)
    self.save
    check_and_mark_unused
  end

  def configure_basic_properties_on_provider(attributes)
    wrapper_agent.modify_load_balancer_attributes(attributes)
  end

  def configure_listeners_on_provider(listeners_list)
    listeners_to_add = listeners_list["listeners"].collect{|l|
      l["Listener"]["lb_port"]=l["Listener"]["lb_port"].to_i
      l["Listener"]["instance_port"]=l["Listener"]["instance_port"].to_i
      l["Listener"]
    }
    listeners_to_remove = []
    remote_load_balancer = wrapper_agent.get
    remote_load_balancer.listeners.each do |listener|
      listener_hash = self.class.format_listener_from_remote(listener)["Listener"]
      if listeners_to_add.include?(listener_hash)
        listeners_to_add -= [listener_hash]
      else
        listeners_to_remove << listener_hash
      end
    end

    listeners_to_remove.each do |listener| wrapper_agent.remove_listener(listener) end if listeners_to_remove.present?
    if listeners_to_add.present?
      listeners_to_add.each do |listener|

        port_no = listener["lb_port"]
        protocol = listener['protocol']

        if !listeners_list["new_ssl_certificate"].nil?
          if !listeners_list["new_ssl_certificate"]["#{port_no}"].nil? && (VALID_SECURE_PROTOCOLS.include?(listener['protocol']) || VALID_SECURE_PROTOCOLS.include?(listener['instance_protocol']))
            cert = create_new_ssl_certificate(listeners_list["new_ssl_certificate"]["#{port_no}"])
            listener["SSLCertificateId"] = cert['Arn']
          end
        end
        sleep 10
        wrapper_agent.add_listener(listener)
      end
    end
    self.listeners = listeners_list["listeners"]
    certificate_name = listeners_list["listeners"].select{|d| d['Listener'].has_key?('SSLCertificateId')}.first['Listener']['SSLCertificateId'].split('/').last rescue nil
    if certificate_name
      #TODO:  later when multiple certifcates are implemented need to modify the code
      self.ssl_certificate = get_available_certificate.find{|hash| hash['ServerCertificateName'] == certificate_name}
      self.new_ssl_certificate = {}
    end
    self.save
    self
  end

  def configure_health_check_on_provider(attributes)
    wrapper_agent.configure_health_check(attributes: attributes)
  end

  def register_instances(instances)
    instance_ids = instances.pluck :provider_id
    wrapper_agent.register_instances(instance_ids: instance_ids) if self.provider_id
    instances.each do |instance| Interface.find_or_create_interfaces(instance,self) end
    elb = wrapper_agent.get
    self.provider_data = ProviderWrappers::AWS.parse_remote_service(elb)
    set_instance_health(elb, "Instance registration is still in progress.")
    self.save!
  end

  def deregister_instances(instances)
    instance_ids = instances.map(&:provider_id)
    wrapper_agent.deregister_instances(instance_ids: instance_ids) if self.provider_id
    self.environment.services.instance_servers.where(provider_id: instance_ids).each do |instance|
      Interface.find_and_delete_connections(instance,self)
    end
    elb = wrapper_agent.get
    self.provider_data = ProviderWrappers::AWS.parse_remote_service(elb)
    set_instance_health(elb, "Instance deregistration currently in progress.")
    self.save!
  end

  def set_instance_health(remote_elb, wait_description)
    CloudStreet.log "fetching instance health waiting."
    remote_elb.wait_for do
      print "."
      remote_elb.instance_health.all? {|h| h["ReasonCode"] != "ELB" && h["Description"] != "Instance is in pending state." }
    end
    self.instance_health = remote_elb.instance_health
    self.data_will_change!
    check_and_mark_unused
  rescue Fog::Errors::TimeoutError => e
    CloudStreet.log "#{e.class} #{e.message} #{e.backtrace}"
  end

  def fetch_and_update_instance_health
    return if self.provider_id.blank? || self.region_id.blank?
    CloudStreet.log "fetching instance health waiting."
    region = Region.find(self.region_id)
    aws_elb_agent = adapter.connection_elb_client(region.code)
    remote_elb = aws_elb_agent.load_balancers.get(self.provider_id)
    return if remote_elb.blank?
    remote_elb.wait_for do
      print "."
      remote_elb.instance_health.all? {|h| h["ReasonCode"] != "ELB" && h["Description"] != "Instance is in pending state." }
    end
    self.instance_health = remote_elb.instance_health
    check_and_mark_unused
  rescue Fog::AWS::ELB::Error => e
    CloudStreet.log("Error: #{e.class} #{e.message} #{e.backtrace}")
  rescue Fog::Errors::TimeoutError => e
    CloudStreet.log "#{e.class} #{e.message} #{e.backtrace}"
  rescue Excon::Error::ServiceUnavailable => e
    puts "Excon Exeption:: => #{e.message}"
  end

  def check_and_mark_unused
    unless self.provider_data.blank?
      if self.provider_data["instances"].blank?
        update_unused(true)
        return
      end

      unless self.instance_health.blank?
        state = instance_health.map { |h| h["State"] }.uniq
        if state.size == 1 && state.first == "OutOfService"
          update_unused(true)
          return
        else
          update_unused(false)
        end
      end
    end

    unless self.data.blank?
      security_group_services = self.fetch_remote_services("Protocols::SecurityGroup")

      unused = false
      security_group_services.each do |security_group|
        if security_group.data["ip_permissions_egress"].blank? && security_group.data["ip_permissions_ingress"].blank?
          unused = true
        end
      end
      update_unused(unused)
    end
  end

  def update_unused(value=true)
    begin
      value = value ? 1 : 0
      self.data = self.data.blank? ? {"unused" => value} : self.data.merge({"unused" => value})
      self.save
    rescue Exception => e
      CloudStreet.log e.message
      CloudStreet.log e.backtrace
    end
  end

  class << self
    def format_listener_from_remote(listener)
      instance_port = listener.instance_port
      lb_port = listener.lb_port
      {
        "Listener"=> {
          "instance_port"=> instance_port,
          "instance_protocol"=> listener.instance_protocol,
          "lb_port"=> lb_port,
          "protocol"=> listener.protocol,
          "SSLCertificateId"=> listener.ssl_id
        }
      }
    end
    #Following properties are not updated
    #[ :region, :ips, :nodes, :protocol, :algorithm, :port, :timeout, :public, :instance_protocol, :instance_protocol_port ]
    def format_attributes_by_raw_data(aws_service)
      # Changing reload listeners' data to match listeners' sync data! :(
       if aws_service.listeners.class.to_s == 'Fog::AWS::ELB::Listeners'
            formatted_listeners = aws_service.listeners.collect do |listener|
              format_listener_from_remote(listener)
            end
       else
            formatted_listeners = aws_service.try(:listeners)
       end

       if formatted_listeners.blank? && aws_service.try(:ListenerDescriptions).present?
        obj = AWSRemoteServiceObject::LoadBalancer.new
        obj.listener_descriptions = aws_service.ListenerDescriptions
        formatted_listeners = obj.get_formatted_listeners
       end
      {
        name: aws_service.id,
        scheme: aws_service.scheme,
        dns_name: aws_service.dns_name,
        hcheck_interval: aws_service.health_check["Interval"],
        response_timeout: aws_service.health_check["Timeout"],
        healthy_threshold: aws_service.health_check["HealthyThreshold"],
        unhealthy_threshold: aws_service.health_check["UnhealthyThreshold"],
        ping_protocol: aws_service.health_check["Target"].split(":").first,
        ping_protocol_port: aws_service.health_check["Target"].split(":").last.split("/").first,
        ping_path: aws_service.health_check["Target"].split(":").last.split("/").last,
        state: "running",
        availability_zones: aws_service.try(:availability_zones).join(','),
        tags: aws_service.try(:tags),
        service_tags: Services::ServiceHelpers::AWS.get_service_tags(aws_service.try(:tags)),
        cross_zone_load_balancing: aws_service.try(:cross_zone_load_balancing),
        connection_timeout: (aws_service.try(:connection_settings_idle_timeout)||aws_service.try(:connection_timeout)),
        connection_draining: aws_service.try(:connection_draining),
        connection_draining_timeout: aws_service.try(:connection_draining_timeout),
        listeners: formatted_listeners,
        instance_health: aws_service.try(:instance_health)
      }.merge(super)
    end

    def fetch_additional_data(remote_elb)
      wrapper = ProviderWrappers::AWS::Networks::LoadBalancer.new(agent: remote_elb.service)
      elb_attributes = wrapper.describe_attributes(remote_elb.id)
      #TODO use provider wrapper
      {
        "tags" => wrapper.list_tags(remote_elb.id),
        "instance_health" => remote_elb.instance_health,
        "listeners" => remote_elb.listeners.collect do |listener|
          format_listener_from_remote(listener)
        end
      }.merge(elb_attributes)
    end

    def fetch_additional_data_for_sync(remote_elb_id, adapter, region_code, options={})
      agent = ProviderWrappers::AWS::Networks::LoadBalancer.elb_agent(adapter, region_code)
      addition_attributes = agent.describe_load_balancer_attributes(remote_elb_id).body["DescribeLoadBalancerAttributesResult"]["LoadBalancerAttributes"] rescue {}
      wrapper = ProviderWrappers::AWS::Networks::LoadBalancer.new(agent: agent)
      instance_health = agent.describe_instance_health(remote_elb_id).body["DescribeInstanceHealthResult"]["InstanceStates"] rescue []
      instance_health.reject! {|h| h["ReasonCode"].eql?("ELB") && h["Description"].eql?("Instance is in pending state.") }
      {
        "tags"                        => wrapper.list_tags(remote_elb_id),
        "cross_zone_load_balancing"   => (addition_attributes["CrossZoneLoadBalancing"] && addition_attributes["CrossZoneLoadBalancing"]["Enabled"]),
        "connection_timeout"          => (addition_attributes["ConnectionSettings"] && addition_attributes["ConnectionSettings"]["IdleTimeout"]),
        "connection_draining"         => (addition_attributes["ConnectionDraining"] && addition_attributes["ConnectionDraining"]["Enabled"]),
        "connection_draining_timeout" => (addition_attributes["ConnectionDraining"] && addition_attributes["ConnectionDraining"]["Timeout"]),
        "instance_health" => instance_health
      }
    end
  end

  def reload_service(aws_service, user)
    super(aws_service, user)
    attributes = self.class.fetch_additional_data(aws_service)
    update(attributes)
  end

  def reload_associations(service, aws_service, user)
    ["subnets", "security_groups", "instances"].each do |assoc_type|
      assoc_type_modified = assoc_type.eql?("subnets") ? "subnet_ids" : assoc_type
      service_provider_ids = get_service_associations(assoc_type)
      aws_service_associations = aws_service.send(assoc_type_modified.to_sym)
      reload_service_associations(aws_service_associations, service_provider_ids, assoc_type)
    end
  end

  def get_service_associations(assoc_type)
    if assoc_type.eql?("instances")
      servers = []
      self.environment.services.instance_servers.each{|instance|
        interface = instance.interfaces.where(interface_type: 'Protocols::LoadBalancer').first
        registered = interface.remote_interfaces.where(service_id: self.id).present? if interface
        servers << instance.provider_id if registered
      }
      servers
    elsif ["subnets", "security_groups"].include?(assoc_type)
      assoc_interface_type = assoc_type.eql?("subnets") ? 'Protocols::Subnet' : 'Protocols::SecurityGroup'
      service_provider_ids = []
      service_interface = interfaces.where(interface_type: assoc_interface_type).first
      if service_interface
        service_interface.remote_interfaces.collect do |i|
          assoc_service = i.service
          service_provider_ids << assoc_service.provider_id
        end
      else
        []
      end
      service_provider_ids
    end
  end

  def reload_service_associations(aws_service_associations, service_provider_ids, assoc_type)
    if assoc_type.eql?("instances")
      options = Hash.new
      if aws_service_associations.present?
        aws_service_associations.each do |association|
          instance = environment.services.instance_servers.where(provider_id: association).first
          if instance.present?
            CloudStreet.log "----------  associating : #{association}"
            Interface.find_or_create_interfaces(instance, self)
          else
            CloudStreet.log "not doing anything for #{association} becasue it is not associated with this environment"
          end
          service_provider_ids = service_provider_ids - [association]
        end
      end
      if service_provider_ids.present?
        service_provider_ids.each do |instance_provider_id|
          instance = environment.services.instance_servers.where(provider_id: instance_provider_id).first
          Interface.find_and_delete_connections(instance, self) if instance.present?
          CloudStreet.log "-------------- detaching #{instance_provider_id}" if instance.present?
        end
      end
    elsif ["subnets", "security_groups"].include?(assoc_type)
      options = Hash.new
      if aws_service_associations.present?
        aws_service_associations.each do |association|
          assoc_service = environment.services.send(assoc_type.to_sym).where(provider_id: association).first
          if assoc_service.present?
            CloudStreet.log "----------  associating : #{association}"
            Interface.find_or_create_interfaces(self,assoc_service)
          else
            CloudStreet.log "not doing anything for #{association} becasue it is not associated with this environment"
          end
          service_provider_ids = service_provider_ids - [association]
        end
      end
      if service_provider_ids.present?
        service_provider_ids.each do |service_p_id|
          assoc_service = environment.services.send(assoc_type.to_sym).where(provider_id: service_p_id).first
          Interface.find_and_delete_connections(self, assoc_service) if assoc_service.present?
          CloudStreet.log "-------------- detaching #{service_p_id}" if assoc_service.present?
        end
      end
    end
  end

  def svg_image_string
    vpc = fetch_remote_services(Protocols::Vpc).first
    vpc_abs_geo = vpc.find_free_space
    lb_img_x = (vpc_abs_geo['x'].to_i + 10)
    lb_img_y = (vpc_abs_geo['y'].to_i + 10)
    update_geo_for_new_service!(lb_img_x, lb_img_y)

    <<-SERVER_STR
    <image xmlns="http://www.w3.org/2000/svg" x="#{lb_img_x}" y="#{lb_img_y}" width="56" height="56" xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="http://#{get_hostname}/assets/services/network/loadbalancer.svg" pointer-events="none"/>
      <g xmlns="http://www.w3.org/2000/svg" transform="translate(#{lb_img_x + 2},#{lb_img_y + 58})"><switch><foreignObject pointer-events="all" class="foreignobject" width="52" height="11" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility"><div xmlns="http://www.w3.org/1999/xhtml" style="display: inline-block; font-size: 12px; font-family: Verdana; color: rgb(176, 176, 176); line-height: 14px; vertical-align: top; overflow: hidden; max-height: 52px; width: 52px; white-space: normal; text-align: center;">#{name}</div></foreignObject><text x="26" y="6" fill="#B0B0B0" text-anchor="middle" font-size="12px" font-family="Verdana">[Object]</text></switch></g></g></svg>
                                                               SERVER_STR
                                                               end

                                                               def find_or_create_interface_connections(&services_context)
                                                                 return unless is_created_and_not_in_error?
                                                                 services_context.call.vpcs.each do |vpc|
                                                                   Interface.find_or_create_interfaces(self, vpc)
                                                                 end

                                                                 services_context.call.security_groups.where(provider_id: self.provider_data["security_groups"]).each do |security_group|
                                                                   Interface.find_or_create_interfaces(self, security_group)
                                                                 end
                                                                 services_context.call.subnets.where(provider_id: self.provider_data["subnet_ids"]).each do |subnet|
                                                                   Interface.find_or_create_interfaces(self,subnet)
                                                                 end

                                                                 services_context.call.instance_servers.where(provider_id: self.provider_data["instances"]).each do |server|
                                                                   Interface.find_or_create_interfaces(server,self)
                                                                 end
                                                               end

                                                               def self.service_ancestors
                                                                 [Services::Vpc, Services::Network::Subnet::AWS, Services::Compute::Server::AWS]
                                                               end

                                                               def self.get_dependencies_of_remote_service(remote_service)
                                                                 #eni ids pending
                                                                 {
                                                                   "Services::Compute::Server::AWS" => remote_service.instances,
                                                                   "Services::Network::Subnet::AWS" => remote_service.subnet_ids,
                                                                   "Services::Network::SecurityGroup::AWS" => remote_service.security_groups,
                                                                   "Services::Network::NetworkInterface::AWS" => []
                                                                 }
                                                               end
                                                               private

                                                               def set_parent_container_id
                                                                 fetch_first_remote_service("Protocols::Vpc").try(:id)
                                                               end

                                                               def parent_service
                                                                 self.interfaces.of_type(Protocols::Vpc).first.remote_interfaces.first.service rescue nil
                                                               end

                                                               def get_listeners(certificates = [])
                                                                 return listeners if certificates.blank? || listeners.blank?
                                                                 listeners.each do |listener|
                                                                   if listener["Listener"]["ssl_type"] == "new" && listener["Listener"]["new_ssl_certificate"].present?
                                                                      existing_aws_certificate = certificate_already_exist?(certificates, listener["Listener"]["new_ssl_certificate"]["certificate_name"])
                                                                    elsif ["SSL", "HTTPS"].include?(listener["Listener"]["protocol"])
                                                                      listener["Listener"]["has_unallocated_ssl"] = true
                                                                      listener["Listener"]["ssl_cert_name"] = listener["Listener"]["SSLCertificateId"].split("/").last unless listener["Listener"]["SSLCertificateId"].nil?
                                                                    else
                                                                      listener["Listener"]["has_unallocated_ssl"] = false
                                                                     unless existing_aws_certificate.blank?
                                                                       listener["Listener"]["ssl_certificate"] = existing_aws_certificate
                                                                       listener["Listener"]["ssl_type"] = "old"
                                                                       listener["Listener"]["new_ssl_certificate"] = false
                                                                     end
                                                                   end
                                                                 end
                                                               end

                                                               def wrapper_agent(get_catched=true)
                                                                 return @wrapper_agent if get_catched && @wrapper_agent.present?

                                                                 @wrapper_agent = ProviderWrappers::AWS::Networks::LoadBalancer.new(service: self, agent: aws_elb_agent)
                                                               end

                                                               # TO DO: Salvage below code when adding support for stikiness policy
                                                               # def update_stickiness_policy(force_update: false)
                                                               #   create_app_cookie_stickiness_policy(lb_name, policy_name, cookie_name)
                                                               #   create_lb_cookie_stickiness_policy(lb_name, policy_name, cookie_expiration_period=nil)
                                                               # end

                                                               def update_connection_draining(provider_lb, force_update: false)
                                                                 if force_update || connection_draining.present?
                                                                   lb.set_connection_draining(connection_draining, connection_draining_timeout)
                                                                 end
                                                               end

                                                               # by default cross_zone_load_balancing is false
                                                               # setting force_update to false, will only update on remote if cross_zone_load_balancing's value is true
                                                               def update_cross_zone_load_balancing(provider_lb, force_update: false)
                                                                 provider_lb.cross_zone_load_balancing = cross_zone_load_balancing if force_update || cross_zone_load_balancing
                                                               end

                                                               def is_present_on_provider?
                                                                 provider_id && aws_elb_agent.load_balancers.get(provider_id).present?
                                                               end

                                                               def get_target
                                                                 ['HTTP', 'HTTPS'].include?(ping_protocol) ? "#{ping_protocol}:#{ping_protocol_port}/#{ping_path}" : "#{ping_protocol}:#{ping_protocol_port}"
                                                               end

                                                               end
