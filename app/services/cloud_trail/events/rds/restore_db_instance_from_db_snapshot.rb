module CloudTrail::Events::Rds::RestoreDBInstanceFromDBSnapshot

  def process
    parse_events_data = parse_events([]) do |response,event_attributes,event|
      response << event_attributes unless event_attributes.blank?
    end
    parse_events_data
  end

  def get_event_attributes(event)
    return { remote_service_id: event["responseElements"]["dBInstanceIdentifier"]}
  end
end
