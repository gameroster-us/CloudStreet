module CloudTrail::Events::ApplicationLoadBalancer::CreateApplicationLoadBalancerListener
  def process
    CTLog.info "****** Inside CreateApplicationLoadBalancerListener******"
    parse_events_data = parse_events([]) do |response, event_attributes, event|
      response << event_attributes.merge("provider_id" => event["requestParameters"]["loadBalancerArn"].split("/")[-2]) unless event_attributes.blank?
    end
    parse_events_data
  end

  def get_event_attributes(event)
    { "listeners" => { "listeners" => event["responseElements"]["listeners"], "action" => "add" } }
  end
end
