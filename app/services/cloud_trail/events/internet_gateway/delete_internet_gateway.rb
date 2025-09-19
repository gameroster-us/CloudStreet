module CloudTrail::Events::InternetGateway::DeleteInternetGateway
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "****** Inside DeleteInternetGateway ******"
    filter = {adapter_id: @adapter.id, region_id: @region.id}
    parse_events_data = parse_events([]) { |response, event_attributes, event| response << event_attributes.merge({"provider_id" => event["requestParameters"]["internetGatewayId"]}) unless event_attributes.blank?; response  }
    process_parse_events_data(parse_events_data) do |parse_events_data, event_ids|
      resource_names = parse_events_data.map { |e| e["provider_id"]}
      InternetGateway.where(provider_id: resource_names).delete_all
      services = Service.synced_services.where(filter).where(provider_id: resource_names)
      self.class.remove_from_solr(services)
      services.delete_all
      Service.in_environment.where(filter).where(provider_id: resource_names).each do |s|
        s.update(state: 'removed_from_provider')
        s.environment.update(state: 'unhealthy') if !s.environment.state.eql?('terminated')
      end
    end
  end
end
