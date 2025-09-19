module CloudTrail::Events::AutoScaling::PutNotificationConfiguration
  MODIFIY_KEYS = %w[notificationTypes topicARN autoScalingGroupName].freeze

  def process
    CTLog.info "****** Inside PutNotificationConfiguration To ASG******"
    parse_events_data = parse_events([]) do |response, event_attributes, event|
      unless event_attributes.blank?
        response << event_attributes.merge("provider_id" => event["requestParameters"]["autoScalingGroupName"])
      end
    end
    parse_events_data
  end

  def get_event_attributes(event)
    MODIFIY_KEYS.each_with_object({}) do |key, response|
      element = event["requestParameters"][key]
      response.merge!(key.underscore => element) if event["requestParameters"].key?(key) && !element.blank?
    end
  end
end
