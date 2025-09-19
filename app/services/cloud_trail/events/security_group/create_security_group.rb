module CloudTrail::Events::SecurityGroup::CreateSecurityGroup
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "****** Inside CreateSecurityGroup ******"
    parse_events_data = parse_events([]) { |response, event_attributes, event| response << event_attributes.merge({"provider_id" => event["responseElements"]["groupId"]}) unless event_attributes.blank?; response  }
    process_parse_events_data(parse_events_data) do |parse_events_data, event_ids|
      resource_names = parse_events_data.map { |e| e["provider_id"]}
      resource_names = resource_names.in_groups_of(200, false)
      resource_names.each do |resources|
        filters = generate_filters(resources, @event_name)
        create_security_group(filters)
      end
    end
    provider_ids = parse_events_data.map { |event| event["provider_id"]}.compact
    self.class.check_security_threat("Services::Network::SecurityGroup::AWS", @adapter, @region, provider_ids)
  end

  def create_security_group(filters)
    sg_objs = fetch_remote_services(filters)
    unless sg_objs.nil?
      service_ids = []
      sg_objs.each do |sg_obj|
        service_id = self.class.create_sg(@adapter.id, @adapter.account_id, @region.id, sg_obj)
        service_ids.push(service_id) unless service_id.blank?
      end
      return if service_ids.blank?
      service_map = {nil => service_ids }
      self.class.connection_updator(adapter.id, region.id, service_map)
      self.class.add_to_solr("Service", service_ids, "Added SG")
    end
  end
end
