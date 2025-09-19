module CloudTrail::Events::AutoScaling::RecordLifecycleActionHeartbeat

  def process
    CTLog.info "****** Inside RecordLifecycleActionHeartbeat To ASG******"
    parse_events_data = parse_events([]) do |response, event_attributes, event|
      unless event_attributes.blank?
        response << event_attributes.merge("provider_id" => event["requestParameters"]["autoScalingGroupName"])
      end
    end
    parse_events_data
  end

  def get_event_attributes(event)
    return { remote_service_id: event["requestParameters"]["autoScalingGroupName"]}
  end

end
