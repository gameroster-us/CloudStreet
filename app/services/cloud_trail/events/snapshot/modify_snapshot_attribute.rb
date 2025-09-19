module CloudTrail::Events::Snapshot::ModifySnapshotAttribute
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "** Inside ModifySnapshotAttribute ***"
    parse_events_data = parse_events([]) { |response, event_attributes, event| response << event_attributes.merge("provider_id" => event["requestParameters"]["snapshotId"]) unless event_attributes.blank?; response }
    process_parse_events_data(parse_events_data) do |parse_events_data, _event_ids|
      parse_events_data.each do |parsed_event|
        snapshot_id = parsed_event["provider_id"]
        permission = parse_permission(parsed_event["attributes"]["requestParameters"]["createVolumePermission"])
        next if permission.blank?
        modify_snapshot(snapshot_id, permission)
      end
    end
  end

  def parse_permission(createVolumePermission)
    return if createVolumePermission.blank?
    createVolumePermission.keys.include?("add") ? "public" : "private"
  end
end
