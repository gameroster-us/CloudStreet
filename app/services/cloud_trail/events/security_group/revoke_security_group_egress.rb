module CloudTrail::Events::SecurityGroup::RevokeSecurityGroupEgress
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "**** Inside RevokeSecurityGroupEgress ****"
    parse_events_data = parse_events([]) { |response, event_attributes, event| response << event_attributes.merge({"provider_id"  => event["requestParameters"]["groupId"]}) unless event_attributes.blank?; response  }
    process_parse_events_data(parse_events_data) do |parse_events_data, event_ids|
      parse_events_data.each do |parsed_event|
        parsed_data = self.class.parse_permissions(parsed_event["attributes"]["ip_permissions_egress"]["items"])
        updated_sg_services(parsed_data, parsed_event["provider_id"])
      end
    end
    provider_ids = parse_events_data.map { |event| event["provider_id"]}.compact
    self.class.check_security_threat("Services::Network::SecurityGroup::AWS", @adapter, @region, provider_ids)
  end

  def get_event_attributes(event)
    {
      "ip_permissions_egress" => event["requestParameters"]["ipPermissions"]
    }
  end

  def updated_sg_services(parsed_data, group_id)
    sg = SecurityGroup.find_by(group_id: group_id, adapter_id: @adapter.id,
                               region_id: @region.id, account_id: @adapter.account_id)
    unless sg.nil?
      sg.ip_permissions_egress -= parsed_data
      sg.provider_data["ip_permissions_egress"] = sg.ip_permissions_egress
      sg.save
    end
    Service.active_reusable_services.where(provider_id: group_id, adapter_id: @adapter.id, region_id: @region.id).each do |service|
      unless service.nil?
        service.ip_permissions_egress -= parsed_data
        service.provider_data = {} if service.provider_data.blank?
        service.provider_data["ip_permissions_egress"] = service.ip_permissions_egress
      end
      service.save
    end
  end

end
