module CloudTrail::Events::RouteTable::DeleteRoute
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "****** Inside DeleteRoute*****"
    parse_events_data = parse_events([]) { |response, event_attributes, event| response << event_attributes unless event_attributes.blank?; response  }
    process_parse_events_data(parse_events_data) do |parse_events_data, event_ids|
      parse_events_data.each do |parsed_event|
        rt_id = parsed_event["attributes"]["requestParameters"]["routeTableId"]
        key = parsed_event["attributes"]["requestParameters"].except!("routeTableId").keys.first
        value =  parsed_event["attributes"]["requestParameters"][key]
        delete_route(rt_id, key, value)
        delete_from_services(rt_id, key, value)
      end
    end
  end

  def get_event_attributes(event)
    {
      "requestParameters" => event["requestParameters"]
    }
  end

  def delete_route(rt_id, key, value)
    rt = RouteTable.find_by(provider_id: rt_id,
                            adapter_id: @adapter.id, region_id: @region.id, account_id: @adapter.account.id)
    unless rt.nil?
      index_to_delete = rt.routes.index { |h| h[key].eql?(value) }
      unless index_to_delete.nil?
        rt.routes.delete_at(index_to_delete)
        rt.provider_data["routes"].delete_at(index_to_delete)
        rt.save
      end
    end
  end

  def delete_from_services(rt_id, key, value)
    services = Service.active_reusable_services.where(provider_id: rt_id,
                                                      adapter_id: @adapter.id, region_id: @region.id, account_id: @adapter.account.id)
    unless services.nil?
      services.each do |service|
        index_to_delete = service.routes.index { |h| h[key].eql?(value) }
        unless index_to_delete.nil?
          service.routes.delete_at(index_to_delete)
          service.provider_data["routes"].delete_at(index_to_delete)
          service.save
        end
      end
    end
  end
end
