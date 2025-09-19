module CloudTrail::Events::Rds::StartDBInstance

  def process
    parse_events_data = parse_events([]) do |response, event_attributes, event|
      response << event_attributes.merge("provider_id" => event["requestParameters"]["dBInstanceIdentifier"]) unless event_attributes.blank?
    end
    parse_events_data
  end

  def get_event_attributes(event)
    {
      "state" => get_cloudstreet_db_state(event["responseElements"]["dBInstanceStatus"])
    }
 end
end