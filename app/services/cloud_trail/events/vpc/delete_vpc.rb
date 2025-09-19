module CloudTrail::Events::Vpc::DeleteVpc
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "**** Inside DeleteVpc ****"
    parse_events_data = parse_events([]) { |response, event_attributes, event| response << event_attributes.merge({"provider_id"  => event["requestParameters"]["vpcId"]}) unless event_attributes.blank?; response  }
    process_parse_events_data(parse_events_data) do |parse_events_data, event_ids|
      resource_names = parse_events_data.map { |e| e["provider_id"]}
      AWSRecord.where(provider_id: resource_names).delete_all
      vpcs = Vpc.where(vpc_id: resource_names, state: 'available', adapter_id: @adapter.id)
      unless vpcs.blank?
        vpcs.update_all(state: "archived")
        Template.joins(:template_vpcs).where(template_vpcs: { vpc_id: vpcs.pluck(:id)}).update_all(state: "unhealthy")
        Vpc.transaction do
          vpcs.each do |vpc|
            vpc.security_groups.get_default_sg.first.try(:destroy)
            vpc.nacl.try(:destroy)
            vpc.route_table.try(:destroy)
            vpc.internet_gateway.remove_from_provider if vpc.internet_gateway
          end
        end
      end
      CloudTrailLog.where(adapter_id: @adapter.id, :provider_id.in => resource_names).delete_all
      VpcSyncedServiceDeleterWorker.set(queue: 'cloud_trail').perform_async(resource_names)
      Service.in_environment.where(provider_id: resource_names).each do |s|
        s.update(state: 'removed_from_provider')
        s.environment.update(state: 'unhealthy') if !s.environment.state.eql?('terminated')
      end
    end
  end
end
