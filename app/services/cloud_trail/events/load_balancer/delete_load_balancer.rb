module CloudTrail::Events::LoadBalancer::DeleteLoadBalancer
  def process
    CTLog.info "****** Inside DeleteLoadBalancer ******"
    parse_events_data = parse_events([]) do |response, event_attributes, event|
      unless event_attributes.blank?
        response << event_attributes.merge("provider_id" => event["requestParameters"]["loadBalancerName"])
      end
      response
    end
    parse_events_data
  end

  def get_event_attributes(event)
    { "remote_service_id" => event["requestParameters"]["loadBalancerName"]}
  end
end
