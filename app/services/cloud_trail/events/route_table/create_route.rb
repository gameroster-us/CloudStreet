module CloudTrail::Events::RouteTable::CreateRoute
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "****** Inside CreateRoute ******"
    parse_events_data = parse_events([]) { |response, event_attributes, event| response << event_attributes.merge({"provider_id" => event["requestParameters"]["routeTableId"]}) unless event_attributes.blank?; response  }
    process_parse_events_data(parse_events_data) do |parse_events_data, event_ids|
      resource_names = parse_events_data.map { |e| e["provider_id"]}
      filters = generate_filters(resource_names, event_name)
      fetch_route_tables(filters)
    end
  end

  def fetch_route_tables(filters)
    rt_objs = fetch_remote_services(filters)
    unless rt_objs.nil?
      rt_objs.each do |rt_obj|
        update_in_base_table(rt_obj)
        update_in_service_table(rt_obj)
      end
    end
  end

  def update_in_base_table(rt_obj)
    rt = RouteTable.find_by(provider_id: rt_obj.provider_id,
                            adapter_id: @adapter.id, region_id: @region.id, account_id: @adapter.account.id)
    unless rt.nil?
      rt.routes = rt_obj.routes
      rt.provider_data["routes"] = rt_obj.routes
      rt.save
    end
  end

  def update_in_service_table(rt_obj)
    service_ids = []
    services = Service.active_reusable_services.where(provider_id: rt_obj.provider_id,
                                                      adapter_id: @adapter.id, region_id: @region.id, account_id: @adapter.account.id)
    unless services.nil?
      services.each do |service|
        service_ids.push(service.id)
        service.routes = rt_obj.routes
        service.provider_data["routes"] = rt_obj.routes
        service.save!
      end
    end
    return if service_ids.blank?
    service_map = {nil => service_ids.compact }
    self.class.connection_updator(@adapter.id, @region.id, service_map)
  end
end
