module CloudTrail::Events::ApplicationLoadBalancer::DeleteApplicationLoadBalancer
  def process
    CTLog.info "****** Inside Delete Application LoadBalancer ******"
    parse_events_data = parse_events([]) do |response, event_attributes, event|
      response << event_attributes.merge("provider_id" => event["requestParameters"]["loadBalancerArn"].split("/")[-2]) unless event_attributes.blank?
    end
    parse_events_data
  end

  def get_event_attributes(event)
    { "remote_service_id" => event["requestParameters"]["loadBalancerArn"].split("/")[-2]}
  end
end
