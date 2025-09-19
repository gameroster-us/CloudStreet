class CloudTrail::Processors::Nacl
  include CloudTrail::Utils::ProcessorHelper

  def self.call(adapter, region_code_map, *args, &block)
    service_type = args[0]["service_type"]
    group_events = args[0]["group_events"]
    group_events.each do |event|
     obj = self.new(adapter, region_code_map[event["region_code"]], event["event_data"], service_type, event['event_name'])
     obj.extend "CloudTrail::Events::Nacl::#{event['event_name']}".constantize
     # obj.process
     yield(obj)
    end
  end

  def initialize(adapter, region, *args)
    @adapter = adapter
    @region = region
    @events = args[0]
    @service_type = args[1]
    @event_name = args[2]
  end

  def self.fetch_default_nacl(vpc_id, adapter, region)
    filters = { vpc_id: vpc_id, default: true }
    nacl_obj = CloudTrail::Processor.fetch_from_aws(adapter.id,region.code,"AWSRecords::Network::Nacl::AWS",filters).first
    create_network_acl(adapter.id, adapter.account_id, region.id, nacl_obj) unless nacl_obj.blank?
  end

  def self.create_network_acl(adapter_id, account_id, region_id, nacl_obj)
    vpc = Vpc.find_by(vpc_id: nacl_obj.provider_vpc_id, adapter_id: adapter_id, state: "available", region_id: region_id)
    return if vpc.blank?
    filters = { adapter_id: adapter_id, region_id: region_id,
    account_id: account_id, provider_id:  nacl_obj.provider_id }
    service = Service.synced_services.where(filters).first
    if service.blank?
      service = Services::Network::Nacl::AWS.new(nacl_obj.get_attributes_for_service_table.merge!(filters))
      service.provider_type = "Providers::AWS"
      service.vpc_id =  Vpc.find_by(filters.except(:provider_id).merge(vpc_id: nacl_obj.provider_vpc_id, state: "available")).try(:id)
      if !service.vpc_id.blank? && service.valid?
        service.save
      end
      create_in_base_table(nacl_obj, filters, service)
    end
    service.id
  end

  def self.create_in_base_table(nacl_obj, filters, service)
    #Only default Nacl is added to Base Table
    if nacl_obj.provider_data["default"]
      return if Nacls::AWS.where(filters).exists?
      nacl = Nacls::AWS.new(nacl_obj.get_attributes_for_base_table.merge!(filters))
      nacl.vpc_id = service.vpc_id
      nacl.provider_vpc_id = nacl.provider_data["vpc_id"]
      nacl.save
    end
  end
end  
