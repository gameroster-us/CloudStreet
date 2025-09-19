module CloudTrail::Events::Vpc::CreateVpc
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "****** Inside CreateVpc ******"
    parse_events_data = parse_events([]) { |response, event_attributes, event| response << event_attributes.merge({"provider_id"  => event["responseElements"]["vpc"]["vpcId"]}) unless event_attributes.blank?; response  }
    process_parse_events_data(parse_events_data) do |parse_events_data, event_ids|
      remote_vpc_ids = parse_events_data.map { |e| e["provider_id"]}
      remote_vpcs = fetch_remote_services
      remote_vpcs = remote_vpcs.select { |vpc| remote_vpc_ids.include?(vpc.provider_id) }
      remote_vpcs.each do |vpc_obj|
        extra_attributes = Services::Vpc.fetch_additional_data_for_sync(vpc_obj.provider_id, @adapter, @region.code)
        unless extra_attributes.blank?
          vpc_obj.enable_dns_hostnames = extra_attributes[:enable_dns_hostnames]
          vpc_obj.enable_dns_resolution = extra_attributes[:enable_dns_resolution]
        end
        remote_ig = AWSRecords::Network::InternetGateway::AWS.get_remote_service_list(@adapter, @region.code, {vpc_id: vpc_obj.provider_id}).first
        unless remote_ig.blank?
          vpc_obj.internet_attached = true
          vpc_obj.internet_gateway_id = remote_ig.id
        end
        filters = { adapter_id: @adapter.id, region_id: @region.id, account_id: adapter.account.id, provider_id: vpc_obj.provider_id }
        vpc = Vpc.where(filters.except(:adapter_id, :provider_id).merge(vpc_id: vpc_obj.provider_id)).first
        if vpc.blank?
          vpc = Vpcs::AWS.new(filters.except(:provider_id))
          vpc.attributes = vpc_obj.get_attributes_for_base_table
          vpc.save
        end
        service_vpc = Service.synced_services.where(filters.except(:adapter_id)).first
        if service_vpc.blank?
          service = Services::Vpc.new(vpc_obj.get_attributes_for_service_table.merge!(filters))
          service.data["vpc_id"] = vpc_obj.provider_id
          service.provider_type = "Providers::AWS"
          if service.valid? && service.save
            service[:vpc_id] = vpc.id
            service.save
            rt_id = CloudTrail::Processors::RouteTable.fetch_default_route_table(service.provider_id, @adapter, @region)
            nacl_id = CloudTrail::Processors::Nacl.fetch_default_nacl(service.provider_id, @adapter, @region)
            sg_id = CloudTrail::Processors::SecurityGroup.fetch_default_sg(service.provider_id, @adapter, @region)
            ig_id = CloudTrail::Processors::InternetGateway.fetch_default_ig(service.provider_id, @adapter, @region)
            service_map = { nil => [ service.id, rt_id, nacl_id, sg_id, ig_id ].compact }
            self.class.connection_updator(adapter.id, region.id, service_map)
            self.class.add_to_solr("Service", [ service.id, rt_id, nacl_id, sg_id, ig_id ].compact!, message="Added services")
          end
        end
      end
    end
  end
end
