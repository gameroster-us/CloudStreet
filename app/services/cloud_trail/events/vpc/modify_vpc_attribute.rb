module CloudTrail::Events::Vpc::ModifyVpcAttribute
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "**** Inside ModifyVpcAttribute ****"
    parse_events_data = parse_events([]) { |response, event_attributes, event| response << event_attributes.merge({"provider_id"  => event["requestParameters"]["vpcId"]}) unless event_attributes.blank?; response  }
    process_parse_events_data(parse_events_data) do |parse_events_data, event_ids|
      parse_events_data.each do |parsed_event|
        parsed_data = parse_request_data(parsed_event["attributes"]["requestParameters"])
        final_hash = create_updated_hash(parsed_data)
        update_vpc(parsed_event["provider_id"], final_hash) unless final_hash.blank?
      end
    end
  end

  def get_event_attributes(event)
    {
      "requestParameters" => event["requestParameters"]
    }
  end

  def update_vpc(vpc_id, final_hash)
    key = final_hash.keys.first
    value = final_hash[key]
    vpc = Vpc.find_by(vpc_id: vpc_id, adapter_id: @adapter.id,
                      account_id: @adapter.account_id, region_id: @region.id)
    unless vpc.blank?
      vpc.data[key] = value
      vpc.save
      Service.active_reusable_services.where(provider_id: vpc_id, adapter_id: @adapter.id).each do |service|
        service.data[key] = value
        service.provider_data[key] = value if service.provider_data
        #Set additional properties for service
        service.set_additional_properties!
        service.save!
      end
    end
  end

  def create_updated_hash(parsed_data)
    new_hash = {}
    if parsed_data.key?("enableDnsHostnames")
      new_hash = { enable_dns_hostnames: parsed_data["enableDnsHostnames"] }
    else
      new_hash = { enable_dns_resolution: parsed_data["enableDnsSupport"] }
    end
    new_hash
  end

  def parse_request_data(requestParameters)
    requestParameters.each_pair do |key,value|
      next unless value.is_a?(Hash)
      requestParameters[key] = value["value"]
    end
  end
end
