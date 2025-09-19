module CloudTrail::Events::Ami::CreateImage
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "******* Inside CreateImage *******"
    parse_events_data = parse_events([]) { |response, event_attributes, event| response << event_attributes.merge({"provider_id" => event["responseElements"]["imageId"]}) unless event_attributes.blank?; response  }
    process_parse_events_data(parse_events_data) do |parse_events_data, event_ids|
      ami_ids = parse_events_data.map { |e| e["provider_id"]}
      create_or_copy_amis(ami_ids)
    end
  end
end
