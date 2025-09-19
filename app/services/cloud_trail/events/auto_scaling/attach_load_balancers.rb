module CloudTrail::Events::AutoScaling::AttachLoadBalancers

  def process
    CTLog.info "****** Inside AttachLoadBalancers To ASG******"
    parse_events_data = parse_events([]) do |response, event_attributes, event|
      unless event_attributes.blank?
        response << event_attributes.merge("provider_id" => event["requestParameters"]["autoScalingGroupName"])
      end
    end
    parse_events_data
  end

  def get_event_attributes(event)
    lb_names = event["requestParameters"]["loadBalancerNames"]
    return { "load_balancer_names" => {"action" => "add", "lb_name" => lb_names} }
  end

end
