module CloudTrail::Events::ApplicationLoadBalancer::SetApplicationLoadBalancerSubnets
  def process
    CTLog.info "****** Inside SetApplicationLoadBalancerSubnets ******"
    parse_events_data = parse_events([]) do |response, event_attributes, event|
      response << event_attributes.merge("provider_id" => event["requestParameters"]["loadBalancerArn"].split("/")[-2]) unless event_attributes.blank?
    end
    parse_events_data
  end

  def get_event_attributes(event)
    { "subnet_ids" => event["responseElements"]["availabilityZones"].pluck("subnetId"), "availability_zones" => event["responseElements"]["availabilityZones"].pluck("zoneName").join(','), "provider_data_availability_zones" => event["responseElements"]["availabilityZones"]}
  end
end
