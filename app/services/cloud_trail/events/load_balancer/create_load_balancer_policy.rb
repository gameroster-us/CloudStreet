module CloudTrail::Events::LoadBalancer::CreateLoadBalancerPolicy
  def process
    CTLog.info "****** Inside CreateLoadBalancerPolicy ******"
    parse_events_data = parse_events([]) do |response, event_attributes, event|
      unless event_attributes.blank?
        response << event_attributes.merge("provider_id" => event["requestParameters"]["loadBalancerName"])
      end
      response
    end
    parse_events_data
  end

  def get_event_attributes(event)
    {"policyTypeName" => event["requestParameters"]["policyTypeName"], "policyName" => event["requestParameters"]["policyName"] }
  end
end
