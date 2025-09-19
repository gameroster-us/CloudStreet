#Refer Commit - 3d32c209d9d35f2a6d643a02229f87d4c824bfd6 for more info during provision
class Services::Network::NetworkInterface::AWS < Services::Network::NetworkInterface
  include Services::ServiceHelpers::AWS
  include Behaviors::AttachDetach::AWS
  is_attachable
  is_detachable

  store_accessor :data, :tags, :description, :status, :subnet_id, :provider_vpc_id, :availablity_zone,
                          :security_groups, :private_ips, :source_dest_check, :private_dns_name, :mac_address,
                          :interface_association, :attachment, :instance_id, :primary
  #TODO add instance_id, public_ip

  AWS_RECORD_SCOPE_METHOD = :network_interfaces
  INTERFACES = [Services::Vpc,  Services::Network::Subnet::AWS,  Services::Network::SecurityGroup::AWS, Services::Compute::Server::AWS, Services::Network::ElasticIP::AWS]

  scope :find_by_attachment_ids, -> (attachemnt_ids) { where("data->'attachment'->>'attachmentId' =  ANY(ARRAY[?])", attachemnt_ids) }

  def connected_to(service, via_services_map)
    if interfaces_includes?(service)
      case service.class.to_s
      when Services::Vpc.to_s
        return is_connected_to_vpc?(service)
      when Services::Network::Subnet::AWS.to_s
        return is_connected_to_subnet?(service)
      when Services::Network::SecurityGroup::AWS.to_s
        return is_connected_to_security_group?(service)
      when Services::Compute::Server::AWS.to_s
        return is_connected_to_server?(service)
      when Services::Network::ElasticIP::AWS.to_s       
        self.parsed_data["private_ips"] = self.parsed_data["private_ips"].collect do|private_ip|
          if private_ip["item"].include?("eipassoc-")
            self.data_will_change!
            service_elastic_ip = (via_services_map[Services::Network::ElasticIP::AWS.to_s]||[]).find{|eip|eip.parsed_provider_data["association_id"].eql?(private_ip["item"])}
            if service_elastic_ip
              private_ip["elasticIp"] = service_elastic_ip.id
              private_ip["hasElasticIP"] = true
            else
              private_ip["hasElasticIP"] = false
              private_ip.delete("elasticIp")
            end
          end
          private_ip
        end
        self.save! if self.data_changed?
        return is_connected_to_eip?(service)
      end
    end
    false
  end

  def change_ip_address_to_service_uuid(elastic_ips)
    parsed_data["private_ips"] = parsed_data["private_ips"].collect do |private_ip|
      unless private_ip["elasticIp"].nil?
        elastic_ip = elastic_ips.find do |eip|
          eip.provider_id.eql?(private_ip["elasticIp"])
        end
        private_ip["elasticIp"] = elastic_ip.id unless elastic_ip.blank?
      end
      private_ip
    end
    data_will_change! unless parsed_data["private_ips"].blank?
  end

  def is_connected_to_vpc?(service)
    if self.provider_data.blank?
      self.connected_via_interface_to(service)
    else
      self.parsed_provider_data["vpc_id"].eql?(service.provider_id)
    end
  end

  def is_connected_to_subnet?(service)
    if self.provider_data.blank?
      self.connected_via_interface_to(service)
    else
      self.parsed_provider_data["subnet_id"].eql?(service.provider_id)
    end
  end

  def is_connected_to_security_group?(service)
    if self.provider_data.blank?
      self.connected_via_interface_to(service)
    else
      self.parsed_provider_data["group_set"].keys.include?(service.provider_id)
    end
  end

  def is_connected_to_server?(service)
    if self.provider_data.blank?
      self.connected_via_interface_to(service)
    else
      self.parsed_provider_data["attachment"] && self.parsed_provider_data["attachment"]["instanceId"].eql?(service.provider_id)
    end
  end

  def is_connected_to_eip?(service)
    return false if service.association_id.blank?
    self.private_ips.each do |private_ip|
      if private_ip["association"] && private_ip["association"]["associationId"].eql?(service.association_id)
        private_ip["item"]          = service.association_id
        private_ip["elasticIp"]     = service.id
        private_ip["hasElasticIP"]  = true
        self.save
        return true
      end
    end
    return false
  end

  def draggable
    return false if self.attachment.present? && ['amazon-rds', 'amazon-elb'].include?(self.attachment['instanceOwnerId'])    
  end

  def drawable
    return false if self.attachment.present? && ['amazon-rds', 'amazon-elb'].include?(self.attachment['instanceOwnerId'])
  end
  
  def provision   
    return if provider_id.present? # i.e. don't create if it's already created    
    CloudStreet.log "----------------------------------------------Creating #{self.class.name} #{self.inspect}"   
    unless primary
      #TOD to provision 
      CloudStreet.log "---------------------------------ENI as non default is not Implemented yet"
    end
    CloudStreet.log "----------------------------------------------Created #{self.class.name} #{self.inspect}"    
      # CloudStreet.log "-------------Its not the default interface -----" #To Do   
  end   
    
  def update_default_network_interface    
    assoc_server = self.fetch_remote_services(Protocols::Server)
    @modified_private_ip_array = self.private_ips 
    if assoc_server   
      interface_ids = assoc_server.first.parsed_provider_data['network_interfaces'].collect {|d|  d['networkInterfaceId']}.compact   
      unless interface_ids.empty?   
        interface_ids.each do |interface_id|
          remote_interface = wrapper_agent.fetch_remote_interface(interface_id)   
          next(interface_id) if remote_interface.nil?   
          if is_default_network_interface?(remote_interface)    
            update_private_eips(interface_id)
            remote_interface = remote_interface.reload
            updated_attrs = self.class.format_attributes_by_raw_data(remote_interface)
            updated_attrs.merge!(provider_id: remote_interface.network_interface_id)  
            updated_attrs.merge!(provider_data: remote_interface.attributes)
            self.update!(updated_attrs)
            update_elastic_ips(interface_id, @modified_private_ip_array)
          end   
        end   
      end   
    end   
  end   

  def wrapper_agent
    @wrapper_agent = ProviderWrappers::AWS::Networks::NetworkInterface.new(service: self, agent: aws_compute_agent)
  end
    
  def update_elastic_ips(interface_id, modified_private_ip_array)
    elastic_ips_service_ids = modified_private_ip_array.collect{|d| d['elasticIp']}.select(&:presence)
    elastic_ips_service_ids.each do |eip_id|
      index_of_eip = modified_private_ip_array.index {|hash| hash['elasticIp'] == eip_id} 
      eip_service = Service.find eip_id
      unless index_of_eip.nil?
        new_eip = modified_private_ip_array[index_of_eip]['elasticIp']
        self.private_ips[index_of_eip].merge!("elasticIp" => new_eip, "hasElasticIP" => true)
        save!
      end
      private_ip_address = self.private_ips.select {|hash| hash['elasticIp'] == eip_id }.first['privateIpAddress']
      options = {'private_ip' => private_ip_address}
      eip_service.attach(self.id, interface_id, options)
    end
  end

  def update_private_eips(interface_id)
    return unless private_ips
    wrapper_agent.update_private_ips(interface_id)
  end
  
  def is_default_network_interface?(remote_obj)   
    remote_obj.attachment["deviceIndex"].eql?("0")    
  end

  def is_in_use?
    !attachment.empty?
  end

  def check_if_can_attach(remote_service_id, attach_options)
    if is_in_use? # cannot attach if it is attached already
      return { error: true, err_msg: :invalid_service_state }
    end

    remote_service = Service.find_by_id(remote_service_id)
    if remote_service.blank?
      return { error: true, err_msg: :parent_service_not_found }
    end

    if remote_service.attached_nics_count >= remote_service.nic_limit.to_i
      return { error: true, err_msg: :nic_limit_exceeded }
    end

    unless remote_service.provider_data['availability_zone'].eql?(self.availablity_zone)
      return { error: true, err_msg: :nic_server_az_mismatch }
    end

    { error: false }
  end

  def check_if_can_detach(remote_service_id)
    unless is_in_use? # cannot detach if it is not attached already
      return { error: true, err_msg: :invalid_service_state }
    end

    remote_service = Service.find_by_id(remote_service_id)
    if remote_service.blank?
      return { error: true, err_msg: :parent_service_not_found }
    end

    if self.primary
      return { error: true, err_msg: :cannot_detach_primary_network_interface }
    end

    { error: false }
  end

  def get_remote_service
    aws_compute_agent.network_interfaces.get(provider_id)
  end

  def terminate_service(params={})
    begin 
      nic = get_remote_service
      nic && nic.destroy
    rescue Exception => error  
      CloudStreet.log "Error: #{error.message}"
      CloudStreet.log "#{error.backtrace}"
    end
  end 

  def handle_private_ips_data(service_uuid_map)
    uuid_map = service_uuid_map.is_a?(Array) ? service_uuid_map.reduce(Hash.new, :merge) : service_uuid_map
    if self.private_ips.present? && uuid_map.present?
      self.private_ips.each do |pip_hash|
        pip_hash["elasticIp"] = uuid_map[pip_hash["elasticIp"]] if pip_hash["elasticIp"].present? && uuid_map.has_key?(pip_hash["elasticIp"])
      end
      self.data_will_change!
    end
  end

  class << self
    def format_attributes_by_raw_data(aws_service)
      attributes = {primary: false}
      attributes.merge!({
        instance_id: aws_service.attachment["instanceId"],
        primary: aws_service.attachment["deviceIndex"].eql?("0")
      }) unless aws_service.attachment.empty?

      attributes.merge!({
        name: aws_service.tag_set["Name"]||aws_service.network_interface_id,
        tags: aws_service.tag_set,
        description: aws_service.description,
        status: aws_service.status,
        subnet_id: aws_service.subnet_id,
        provider_vpc_id: aws_service.vpc_id,
        availablity_zone: aws_service.availability_zone,
        security_groups: aws_service.group_set,
        mac_address: aws_service.mac_address,
        private_ips: aws_service.private_ip_addresses,
        source_dest_check: aws_service.source_dest_check,
        private_dns_name: aws_service.private_dns_name,
        interface_association: aws_service.association,
        attachment: aws_service.attachment,
        state: "running"
      }).merge!(super)
    end

    def fetch_additional_data(remote_eni)
      return { private_ips: [] } unless remote_eni.present?
      filters = { "network-interface-id"=>remote_eni.network_interface_id }
      wrapper = ProviderWrappers::AWS::Networks::ElasticIP.new(agent: remote_eni.service)
      elastic_ips = ProviderWrappers::AWS::Networks::ElasticIP.all(wrapper.agent, filters)
      private_ips = remote_eni.private_ip_addresses.collect do|private_ip|
        eip = elastic_ips.find{|eip| eip.association_id.eql?(private_ip["item"])}
        private_ip["elasticIp"] = eip.public_ip if eip
        private_ip
      end
      { private_ips: private_ips }
    end

    def create_nic_service(server_obj, remote_eni)
      nic = Services::Network::NetworkInterface::AWS.directory.non_generic_services.first.dup
      attributes = format_attributes_by_raw_data(remote_eni).merge({
        adapter_id: server_obj.adapter_id,
        account_id: server_obj.account_id,
        region_id: server_obj.region_id,
        provider_id: remote_eni.network_interface_id,
        provider_data: JSON.parse(remote_eni.to_json)
      })
      nic.attributes = attributes
      nic.save!
      server_obj.environment.services << nic
      nic.find_or_create_default_interface_connections
      nic.find_or_create_interface_connections{nic.environment.services}
      nic.set_additional_properties!
    end

    def get_remote_service_provider_id(remote_service)
      remote_service.network_interface_id
    end

    def get_dependencies_of_remote_service(remote_service)
      sg_ids = remote_service.group_set.map{|sg_id, sg_name| sg_id}
      dependency_hash = {
        "Services::Network::SecurityGroup::AWS" => sg_ids,
        "Services::Network::Subnet::AWS" => remote_service.subnet_id
      }
      dependency_hash.merge!("Services::Network::ElasticIP::AWS" => remote_service.association["publicIp"]) if remote_service.association.present? && remote_service.association.has_key?("publicIp")
      dependency_hash
    end
  end

 def properties
    properties = [
      {
        form_options: {
          type: "private_ips_type",
          options: [],
          required: true
        },
        name: "private_ips",
        title: "Private Ips",
        value: private_ips.try(:first) || []  
      },
      {
        form_options: {
          type: "hidden",
          required: false,
          readonly: "readonly"
        },
        name: "primary",
        title: "Primary",
        value: primary
      },
      {
        form_options: {
          type: "text",
          required: true
        },
        name: "description",
        title: "Description",
        value: description||""
      },{
        form_options: {
          type: "hidden",
          readonly: "readonly"
        },
        name: "mac_address",
        title: "Mac Address",
        value: mac_address||""
      },
      {
        form_options: {
          type: "checkbox",
          required: false
        },
        name: "source_dest_check",
        title: "Source Destination Check",
        value: source_dest_check
      }
    ]
  end

  def parent_services
    [Services::Vpc, Services::Network::AvailabilityZone, Services::Network::SecurityGroup::AWS, Services::Network::Subnet::AWS, Services::Network::LoadBalancer::AWS]
  end

  def find_or_create_interface_connections(&services_context)
    return unless is_created_and_not_in_error?
    services_context.call.vpcs.where(provider_id: provider_vpc_id).each do |vpc|
      Interface.find_or_create_interfaces(self, vpc)
    end

    services_context.call.subnets.where(provider_id: subnet_id).each do |subnet|
      Interface.find_or_create_interfaces(self, subnet)
    end

    services_context.call.security_groups.where(provider_id: security_groups.keys).each do |security_group|
      Interface.find_or_create_interfaces(self, security_group)
    end

    services_context.call.instance_servers.where(provider_id: instance_id).each do |server|
      Interface.find_or_create_interfaces(self, server)
    end if instance_id

    updated_ips = change_private_ips_elastic_ip_to_associated_service_ids(&services_context)
    self.private_ips = updated_ips
    self.data_will_change!
    self.save!

    # TODO RouteTable
  end

  def change_private_ips_elastic_ip_to_associated_service_ids(&services_context)
    self.private_ips.collect do|private_ip|
      if private_ip["elasticIp"]
        service_elastic_ip = services_context.call.elastic_ips.find_by_name(private_ip["elasticIp"])
        if service_elastic_ip
          private_ip["elasticIp"] = service_elastic_ip.id
        else
          private_ip.delete("elasticIp")
        end
      end
      private_ip
    end
  end

  def is_detached?
    self.status.eql?("available")
  end

  def attach(instance_id, instance_provider_id, attach_options={})
    server = Services::Compute::Server::AWS.find(instance_id)
    device_index = (server.get_available_indexes.first || 1)
    response = aws_compute_agent.attach_network_interface(self.provider_id, server.provider_id, device_index)
    Interface.find_or_create_interfaces(self, server)
    self.instance_id = server.provider_id
    self.status = 'in-use'
    self.attachment = {
      "attachmentId"=>response.body['attachmentId'],
      "instanceId"=>server.provider_id,
      "instanceOwnerId"=>server.provider_data['ownerId'],
      "deviceIndex"=>device_index.to_s,
      "status"=>"attached",
      "attachTime"=>Time.now.strftime(CommonConstants::DEFAULT_TIME_FORMATE),
      "deleteOnTermination"=>"false"
    }
    self.provider_data["attachment"].clear
    self.provider_data["attachment"].merge(self.attachment)
    self.provider_data.merge!("status" => 'in-use')
    self.set_additional_properties!
    self.error_message=""
    self.save!
    #TODO write a script to set the values of existing elastic ips -> server_ids
    self.private_ips.collect{|pip| pip["elasticIp"]}.each do|eip|
      if eip
        ip = Service.find(eip)
        ip.server_id = server.provider_id
        ip.data_will_change!
        ip.save!
      end
    end
  end

  def detach(instance_id, instance_provider_id)
    aws_compute_agent.detach_network_interface(attachment["attachmentId"]) rescue Fog::Compute::AWS::NotFound
    server = Service.where(id: instance_id).first
    Interface.find_and_delete_connections(self, server) if server
    self.instance_id = nil
    self.status = 'available'
    self.attachment.clear
    self.provider_data["attachment"].clear
    self.provider_data.merge!("status" => 'available')
    self.set_additional_properties!
    self.error_message=""
    self.save!
    self.private_ips.collect{|pip| pip["elasticIp"]}.each do|eip|
      if eip
        ip = Service.find(eip)
        ip.server_id = nil
        ip.data_will_change!
        ip.save!
      end
    end
    #identify the properties of Server to update
    #server.provider_data.network_interfaces, private_ip to discuss
  end

  private

  def set_parent_container_id
    first_remote_service = fetch_first_remote_service("Protocols::Subnet")
      if first_remote_service.present?
        first_remote_service.id
      else
        puts "#{self.try(:id)} | #{self.try(:name)} of #{self.try(:type)} Interface connection is removed from provider hence not found"
        nil
      end
  end
end
