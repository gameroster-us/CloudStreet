module CloudTrail::Events::AutoScaling::SuspendProcesses
  def process
    CTLog.info "****** Inside SuspendProcesses For ASG******"
    parse_events_data = parse_events([]) do |response, event_attributes, event|
      unless event_attributes.blank?
        response << event_attributes.merge("provider_id" => event["requestParameters"]["autoScalingGroupName"])
      end
    end
    parse_events_data
  end

  def get_event_attributes(event)
    { "AutoScalingGroupName" => event["requestParameters"]["autoScalingGroupName"], "scaling_processes" => event["requestParameters"]["scalingProcesses"]}
  end
end
