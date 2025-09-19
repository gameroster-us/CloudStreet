module CloudTrail::Events::Nacl::DeleteNetworkAclEntry
  include CloudTrail::Utils::EventConfigHelper
  include CloudTrail::Events::Nacl::Helper

  def process
    CTLog.info "****** Inside DeleteNetworkAclEntry ******"
    parse_events_data = parse_events([]) { |response, event_attributes, event| response << event_attributes unless event_attributes.blank?; response  }
    vpc_provider_ids = get_vpc_provider_ids(parse_events_data)
    process_parse_events_data(parse_events_data) do |parse_events_data, event_ids|
      parse_events_data.each do |parsed_event|
        nacl_id =  parsed_event["attributes"]["requestParameters"]["networkAclId"]
        nacl_params = parsed_event["attributes"]["requestParameters"].except!("networkAclId")
        delete_nacl_entry(nacl_id, nacl_params)
      end
    end
    scan_security_threat_for_vpc(vpc_provider_ids)
  end

  def get_event_attributes(event)
    {
      "requestParameters" => event["requestParameters"]
    }
  end

  def delete_nacl_entry(nacl_id, nacl_params)
    filters = { adapter_id: @adapter.id, account_id: @adapter.account_id,
                region_id: @region.id, provider_id: nacl_id }
    key1 = "ruleNumber"
    key2 = "egress"
    nacl = Nacl.find_by(filters)
    if nacl.present?
      index_to_delete = nacl.entries.index { |h| h[key1].eql?(nacl_params[key1]) && h[key2].eql?(nacl_params[key2]) }
      unless index_to_delete.nil?
        nacl.entries.delete_at(index_to_delete)
        nacl.provider_data["entries"].delete_at(index_to_delete)
        nacl.save
      end
    end
    update_nacl_services(nacl_params, filters, key1, key2)
  end

  def update_nacl_services(nacl_params, filters, key1, key2)
    services = Service.active_reusable_services.where(filters)
    unless services.nil?
      services.each do |service|
        index_to_delete = service.entries.index { |h| h[key1].eql?(nacl_params[key1]) && h[key2].eql?(nacl_params[key2]) }
        unless index_to_delete.nil?
          service.entries.delete_at(index_to_delete)
          service.provider_data["entries"].delete_at(index_to_delete)
          service.save
        end
      end
    end
  end
end
