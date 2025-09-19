module CloudTrail::Events::InternetGateway::DetachInternetGateway
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "****** Inside DetachInternetGateway ******"
    parse_events_data = parse_events([]) { |response, event_attributes, event| response << event_attributes.merge({"provider_id" => event["requestParameters"]["internetGatewayId"]}) unless event_attributes.blank?; response  }
    process_parse_events_data(parse_events_data) do |parse_events_data, event_ids|
      parse_events_data.each do |parsed_event|
        vpc_id = parsed_event["attributes"]["requestParameters"]["vpcId"]
        ig_id = parsed_event["attributes"]["requestParameters"]["internetGatewayId"]
        process_detach_event(vpc_id, ig_id)
      end
    end
  end

  def get_event_attributes(event)
    {
      "requestParameters" => event["requestParameters"]
    }
  end

  def process_detach_event(vpc_id, ig_id)
    vpc_filters = { adapter_id: @adapter.id, account_id: @adapter.account_id,
                    region_id: @region.id, vpc_id: vpc_id }
    ig_filters = { adapter_id: @adapter.id, account_id: @adapter.account_id,
                   region_id: @region.id, provider_id: ig_id }
    detach_vpc_ig(vpc_filters, ig_filters)
    update_services(vpc_filters, ig_filters, vpc_id)
  end

  def detach_vpc_ig(vpc_filters, ig_filters)
    vpc = Vpc.find_by(vpc_filters.merge!(state: "available"))
    ig = InternetGateway.find_by(ig_filters)
    if vpc.present? && ig.present?
      vpc.internet_attached = false
      vpc.provider_data["internet_attached"] = false
      vpc.provider_data["internet_gateway_id"] = nil
      vpc.save
      ig.vpc_id = nil
      ig.save
    end
  end

  def update_services(vpc_filters, ig_filters, vpc_id)
    vpc_services = Service.active_reusable_services.where(vpc_filters.except!(:vpc_id, :state).merge!(provider_id: vpc_id))
    ig_services = Service.active_reusable_services.where(ig_filters)
    vpc_services.each do |service|
      service.internet_attached = false
      service.internet_gateway_id = nil
      service.save
    end
    ig_services.each do |service|
      service.vpc_id = nil
      service.provider_data["attachment_set"]["vpcId"] = nil
      service.save
    end
    ig_services.update_all({vpc_id: nil})
  end
end
