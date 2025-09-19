module CloudTrail::Events::RouteTable::ReplaceRouteTableAssociation
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "****** Inside ReplaceRouteTableAssociation ******"
    key = "routeTableAssociationId"
    parse_events_data = parse_events([]) { |response, event_attributes, event| response << event_attributes.merge({"provider_id" => event["requestParameters"]["routeTableId"]}) unless event_attributes.blank?; response  }
    process_parse_events_data(parse_events_data) do |parse_events_data, event_ids|
      resource_names = parse_events_data.map { |e| e["provider_id"]}
      parse_events_data.each do |parsed_event|
        assoc_id = parsed_event["attributes"]["associationId"]
        old_rt = Services::Network::RouteTable::AWS.find_by_association_id(assoc_id, @adapter, @region.id).pluck(:provider_id).uniq.first
        unless old_rt.nil?
          update_old_rt(assoc_id, old_rt, key)
        end
      end
      filters = generate_filters(resource_names, @event_name)
      update_route_tables(filters)
    end
  end

  def get_event_attributes(event)
    {
      "associationId" => event["requestParameters"]["associationId"]
    }
  end

  def update_old_rt(assoc_id, old_rt, key)
    services = Service.includes(:environment).active_reusable_services.where(provider_id: old_rt,
                                                                             adapter_id: @adapter.id, region_id: @region.id, account_id: @adapter.account.id)
    service_map = {}
    unless services.nil?
      services.group_by{ |s| s.environment.try(:id) }.each do |env_id, services|
        services.each do |rt_service|
          index_to_delete = rt_service.associations.index { |h| h[key].eql?(assoc_id) }
          unless index_to_delete.nil?
            rt_service.associations.delete_at(index_to_delete)
            rt_service.provider_data["associations"].delete_at(index_to_delete)
            rt_service.save
          end
        end
        env_id.blank? ? service_map.merge!({nil => services.map(&:id) }) : service_map.merge!({ env_id => services.map(&:id) })
      end
    end
    self.class.connection_updator(@adapter.id, @region.id, service_map)
  end

  def update_in_service_table(rt_obj)
    services = Service.includes(:environment).active_reusable_services.where(provider_id: rt_obj.provider_id,
                                                                             adapter_id: @adapter.id, region_id: @region.id, account_id: @adapter.account.id)
    service_map = {}
    unless services.nil?
      services.group_by{ |s| s.environment.try(:id) }.each do |env_id, services|

        services.each do |rt_service|
          rt_service.associations = rt_obj.associations
          rt_service.provider_data["associations"] = rt_obj.associations
          rt_service.save
        end

        env_id.blank? ? service_map.merge!({nil => services.map(&:id) }) : service_map.merge!(env_rt_subnet_conn(env_id, services))
      end
    end

    self.class.connection_updator(@adapter.id, @region.id, service_map)
  end

  def update_route_tables(filters)
    rt_objs = fetch_remote_services(filters)
    unless rt_objs.nil?
      rt_objs.each do |rt_obj|
        update_in_service_table(rt_obj)
        search_filters = { adapter_id: @adapter.id, account_id: @adapter.account_id,
                           region_id: @region.id, provider_id: rt_obj.provider_id }
        associations  = rt_obj.provider_data["associations"]
        if associations && associations.any?{|hsh| hsh["main"].eql?(true)}
          fresh_filters = { adapter_id: @adapter.id, account_id: @adapter.account_id,
                            region_id: @region.id }
          create_rt_on_base_table(rt_obj, fresh_filters)
        end
        rt = RouteTable.find_by(search_filters)
        unless rt.nil?
          rt.associations = rt_obj.associations
          rt.provider_data = rt_obj.provider_data
          rt.save
        end
      end
    end
  end

  def env_rt_subnet_conn(env_id, route_tables)
    environment = Environment.find(env_id)
    vpc_id      = route_tables.first.vpc_id
    exisiting_subnets_provider_ids = environment.services.subnets.pluck(:provider_id)
    subnet_provider_ids = route_tables.each_with_object([]) { |s,memo| memo.concat(s.associations.pluck(:subnetId)) }
    subnets_to_copy = subnet_provider_ids - exisiting_subnets_provider_ids
    return {} if subnets_to_copy.blank?
    synced_subnets = Service.where(adapter_id: @adapter.id, region_id: @region.id, provider_id: subnets_to_copy).synced_services
    service_ids = synced_subnets.each_with_object([]) do |synced_subnet, s_ids|
      s = synced_subnet.dup
      s.id = SecureRandom.uuid
      s.vpc_id = vpc_id
      s.save
      s_ids << s.id
      EnvironmentService.find_or_create_by(environment_id: env_id, service_id: s.id)
    end
    { env_id => service_ids + route_tables.map(&:id) }
  end

  def create_rt_on_base_table(rt_obj, fresh_filters)
    return if RouteTable.where(fresh_filters).where(provider_id: rt_obj.provider_id).first
    vpc = Vpc.where(fresh_filters).where(vpc_id: rt_obj.vpc_id, state: "available").first
    return if vpc.nil?
    rt_to_delete = RouteTable.where(fresh_filters).where(vpc_id: vpc.id).first
    rt_to_delete.destroy unless rt_to_delete.nil?
    rt_to_create = RouteTables::AWS.new(rt_obj.get_attributes_for_base_table.merge!(fresh_filters))
    rt_to_create.vpc_id = vpc.id
    rt_to_create.save
  end
end
