module CloudTrail::Events::KeyPair::DeleteKeyPair
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "**** Inside Delete KeyPair ****"
    parse_events_data = parse_events([]) { |response, event_attributes, event| response << event_attributes.merge({"provider_id" => event["requestParameters"]["keyName"]}) unless event_attributes.blank?; response }
    process_parse_events_data(parse_events_data) do |parse_events_data, event_ids|
      resource_names = parse_events_data.map { |e| e["provider_id"]}
      filters = { adapter_id: @adapter.id, account_id: @adapter.account_id, region_id: @region.id}
      resource_names.each do |key_name|
        Resources::KeyPair.where(filters.merge(name: key_name)).delete_all
      end
    end
  end
end
