module CloudTrail::Events::NetworkInterface::AssignPrivateIPAddresses
  def process
    parse_events_data = parse_events([]) do |response, event_attributes, event|
      unless event_attributes.blank?
        response << event_attributes.merge("provider_id" => event["requestParameters"]["networkInterfaceId"])
      end
    end
    parse_events_data
  end

  def get_event_attributes(event)
    { "private_ip_addresses" => { "actions" => "assign", "ips" => event["requestParameters"]["privateIpAddressesSet"]["items"]} }
  end
end
