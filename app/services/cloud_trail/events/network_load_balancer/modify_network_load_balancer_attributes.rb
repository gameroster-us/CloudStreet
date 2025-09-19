module CloudTrail::Events::NetworkLoadBalancer::ModifyNetworkLoadBalancerAttributes
  def process
    CTLog.info "****** Inside ModifyNetworkLoadBalancerAttributes ******"
    parse_events_data = parse_events([]) do |response, event_attributes, event|
      response << event_attributes.merge("provider_id" => event["requestParameters"]["loadBalancerArn"].split("/")[-2]) unless event_attributes.blank?
    end
    parse_events_data
  end

  def get_event_attributes(event)
    attributes = {}
    lb_attributes = event["responseElements"] && event["responseElements"]["attributes"]
    return {} if lb_attributes.blank?
    lb_attributes.each do |attrs|
      if attrs["key"].eql?("access_logs.s3.enabled")
        attributes.merge!({"access_logs_s3_enabled" => attrs["value"]})
      elsif attrs["key"].eql?("access_logs.s3.bucket")
        attributes.merge!({"access_logs_s3_bucket" => attrs["value"]})
      elsif attrs["key"].eql?("load_balancing.cross_zone.enabled")
        attributes.merge!({"load_balancing_cross_zone_enabled" => attrs["value"]})
      elsif attrs["key"].eql?("access_logs.s3.prefix")
        attributes.merge!({"access_logs_s3_prefix" => attrs["value"]})
      elsif attrs["key"].eql?("deletion_protection.enabled")
        attributes.merge!({"deletion_protection_enabled" => attrs["value"]})
      end
    end
    return attributes
  end
end
