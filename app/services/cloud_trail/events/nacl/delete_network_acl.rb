module CloudTrail::Events::Nacl::DeleteNetworkAcl
  include CloudTrail::Utils::EventConfigHelper
  include CloudTrail::Events::Nacl::Helper

  def process
    CTLog.info "****** Inside DeleteNetworkAcl ******"
    filter = {adapter_id: @adapter.id, region_id: @region.id}
    parse_events_data = parse_events([]) { |response, event_attributes, event| response << event_attributes.merge({"provider_id" => event["requestParameters"]["networkAclId"]}) unless event_attributes.blank?; response  }
    vpc_provider_ids = get_vpc_provider_ids(parse_events_data)
    process_parse_events_data(parse_events_data) do |parse_events_data, event_ids|
      resource_names = parse_events_data.map { |e| e["provider_id"]}
      Nacl.where(provider_id: resource_names).delete_all
      services = Service.synced_services.where(filter).where(provider_id: resource_names)
      self.class.remove_from_solr(services)
      services.delete_all
      Service.in_environment.where(filter).where(provider_id: resource_names).each do |s|
        s.update(state: 'removed_from_provider')
        s.environment.update(state: 'unhealthy') if !s.environment.state.eql?('terminated')
      end
    end
    scan_security_threat_for_vpc(vpc_provider_ids)
  end
end
