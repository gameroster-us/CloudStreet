class TemplateServiceInfo
  attr_accessor :id, :name, :provider_id, :type, :generic, :version, :geometry, :provides, :properties,
                :depends, :geometry, :interfaces, :internal, :container, :sink, :expose, :additional_properties, :user,
                :tags, :name_free_text, :display_name, :existing_subnet_group, :service_tags, :is_reusable, :supported_encryption_flavors, :cost_by_hour, :subnet_data, :created_at


   SUBNETGROUP_CLASS = "Services::Network::SubnetGroup::AWS"
   SUBNET_CLASS = "Services::Network::Subnet::AWS"    
   REUSABLE_SERVICE_CLASS = ['Services::Network::Subnet::AWS', 'Services::Network::SecurityGroup::AWS', 'Services::Network::SubnetGroup::AWS']         

  def initialize(service, user, is_unallocated=false)
    @id = service.id
    @provider_id = service.provider_id if service.type.eql?("Services::Compute::Server::AWS")
    if service.is_subnet?
      @name = (!service.tags.blank?) ?  service.tags['Name'] : service.name
    else
      @name = service.name
    end
    if service.type.eql?("Services::Network::RouteTable::AWS")
      unless service.vpc.blank?
        if service.vpc.internet_gateway.present?
          unless service.vpc.internet_attached
            service.data["routes"].reject! { |rt| rt["gatewayId"] == service.vpc.internet_gateway.provider_id }
          end
        end
      end
    end
    if service.is_volume?
      @created_at =  service.created_at.present? ? service.created_at.strftime(CommonConstants::DEFAULT_TIME_FORMATE) : Time.now.utc.strftime(CommonConstants::DEFAULT_TIME_FORMATE)
    end
    if service.class.to_s.eql?(SUBNETGROUP_CLASS)
      @existing_subnet_group = SubnetGroup.find_by_name(service.name).present?
    end
    if service.class.to_s.eql?(SUBNET_CLASS)
      @subnet_data = {
        availability_zone: service.availability_zone,
        cidr_block: service.cidr_block,
        generic_type: service.generic_type,
        id: service.id,
        name: service.name,
        region_id: service.region_id,
        service_tags: service.parsed_data["service_tags"],
        state: service.state,
        type: service.type,
        vpc_id: service.vpc_id
      }
    end
    @name_free_text = service.data['name_free_text'] if service.data
    @geometry = service.geometry

    @depends  = service.depends.map { |i| InterfaceInfo.new(i) }
    @provides = service.provides.map { |i| InterfaceInfo.new(i) }

    @type = service.class.to_s
    service.user = user
    service.is_unallocated = is_unallocated
    @user = user
    @properties = service.properties.map do
      |a| 
      Property.new(a[:name], service.send(a[:name].to_sym), a[:form_options], a[:title], a[:text], a[:validation])
    end
    service.reload if service.type.eql?("Services::Network::AutoScalingConfiguration::AWS")
    @additional_properties = service.additional_properties
    @display_name = service.get_soe_name('soename') if service.type.eql?('Services::Compute::Server::AWS')
    @interfaces = service.interfaces.extend InterfaceRepresenter

    @internal = service.internal
    @container = service.container
    @cost_by_hour = service.cost_by_hour
    @sink = service.sink
    @expose = service.expose
    if Service::LB_SERVICE_TYPES.include?(service.type) && service.data
      @tags = (service.data && service.parsed_data["tags"]) ?  ( (service.parsed_data['tags'].class == Array) ? get_tag_map(service.parsed_data['tags']) : service.parsed_data['tags'] ) : {}
    elsif service.provider_data && service.parsed_provider_data['tag_set']
      @tags = (service.provider_data && service.parsed_provider_data['tag_set']) ?  ( (service.parsed_provider_data['tag_set'].class == Array) ? get_tag_map(service.parsed_provider_data['tag_set']) : service.parsed_provider_data['tag_set'] ) : {}
    elsif service.provider_data && service.parsed_provider_data['tags']
      @tags = (service.provider_data && service.parsed_provider_data['tags']) ?  ( (service.parsed_provider_data['tags'].class == Array) ? get_tag_map(service.parsed_provider_data['tags']) : service.parsed_provider_data['tags'] ) : {}
    end
    @service_tags = service.parsed_data["service_tags"] rescue []
    @is_reusable = service.is_reusable? if REUSABLE_SERVICE_CLASS.include?("#{service.class}")
    @supported_encryption_flavors = service.class::SUPPORTED_FLOVOR_IDS_FOR_ENCRYPTED_RDS if service.class.to_s.eql?('Services::Database::Rds::AWS')
  end

  def get_tag_map(tags_array)
    hash = {}
    tags_array.each { |tag| hash[tag['Key']] = tag['Value'] if tag['Key'] }
    hash
  end
end
