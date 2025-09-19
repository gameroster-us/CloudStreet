module CloudTrail::Events::ApplicationLoadBalancer::DeleteApplicationLoadBalancerListener
  def process
    CTLog.info "****** Inside DeleteApplicationLoadBalancerListener******"
    parse_events_data = parse_events([]) do |response, event_attributes, event|
      response << event_attributes.merge("provider_id" => event["requestParameters"]["listenerArn"].split("/")[-3]) unless event_attributes.blank?
    end
    parse_events_data
  end

  def get_event_attributes(event)
    { "listeners" => { "listeners" => event["requestParameters"]["listenerArn"], "action" => "delete" }}
  end
end
