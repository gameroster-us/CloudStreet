module CloudTrail::Events::RouteTable::CreateRouteTable
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "****** Inside CreateRouteTable ******"
    parse_events_data = parse_events([]) { |response, event_attributes, event| response << event_attributes.merge({"provider_id" => event["responseElements"]["routeTable"]["routeTableId"]}) unless event_attributes.blank?; response  }
    process_parse_events_data(parse_events_data) do |parse_events_data, event_ids|
      resource_names = parse_events_data.map { |e| e["provider_id"]}
      filters = generate_filters(resource_names, event_name)
      create_route_table(filters)
    end
  end

  def create_route_table(filters)
    rt_objs = fetch_remote_services(filters)
    unless rt_objs.nil?
      service_ids = []
      rt_objs.each do |rt_obj|
        service_id = self.class.create_rt(@adapter.id, @adapter.account_id, @region.id, rt_obj)
        service_ids.push(service_id) unless service_id.blank?
      end
      return if service_ids.blank?
      service_map = {nil => service_ids }
      self.class.connection_updator(@adapter.id, @region.id, service_map)
      self.class.add_to_solr("Service", service_ids, "Added RT")
    end
  end
end
