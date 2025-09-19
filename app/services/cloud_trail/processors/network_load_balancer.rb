class CloudTrail::Processors::NetworkLoadBalancer
  include CloudTrail::Utils::ProcessorHelper

  def self.call(adapter, region_code_map, *args)
    service_type = args[0]["service_type"]
    group_events = args[0]["group_events"]
    group_events.each do |event|
      obj = new(adapter, region_code_map[event["region_code"]], event["event_data"], service_type, event['event_name'])
      obj.extend "CloudTrail::Events::NetworkLoadBalancer::#{event['event_name']}".constantize
      yield(obj)
    end
  end

  def initialize(adapter, region, *args)
    @adapter = adapter
    @region = region
    @event_name = args[2]
    @events = args[0]
    @service_type = args[1]
    @action = if @event_name == "CreateNetworkLoadBalancer"
                "create"
              elsif @event_name == "DeleteNetworkLoadBalancer"
                "delete"
              else
                "modify"
            end
  end

  def self.update_services(service_type, adapter_id, region_id, modified_events)
    sync_modified_events(service_type, adapter_id, region_id, modified_events) do |service, events|
      connection_change = {}
      adapter = Adapter.find(adapter_id)
      region_code = Region.find(region_id).code
      v2_elb_client = adapter.connection_v2_elb_client(region_code)
      events.each do |event|
        event["attributes"].each do |key, value|
          case key
          when "security_groups"
            #value = ((service.data["security_groups"] || []) + value).uniq
            service.security_groups = []
            service.security_groups = value
          when "subnet_ids"
            #value = ((service.data["subnet_ids"] || []) + value).uniq
            service.subnet_ids = []
            service.subnet_ids = value
          when "provider_data_availability_zones"
            key = "availability_zones"
            service.provider_data[key] = value
          when "listeners"
            begin
              service.listeners = []
              res = v2_elb_client.describe_listeners(load_balancer_arn: service.provider_data["load_balancer_arn"]).to_h
              service.listeners = res[:listeners].blank? ? [] : res[:listeners]
            rescue Aws::ElasticLoadBalancingV2::Errors, StandardError => e
              if e.code.eql?("AccessDenied")
                CTLog.error "=======#{e.message} Access denied for #{adapter.name} in #{region_code} ===="
              else
                CTLog.error e.message
                CTLog.error e.backtrace
              end
            end
          else
            service.send("#{key}=", value) if service.respond_to?(key.to_sym)
          end
          service.provider_data[key] = value if service.provider_data.key?(key)
        end
      end
      next service, connection_change
    end
  end

  def self.remove_services(adapter_id, event_data)
    lb_ids = event_data.map { |event| event["attributes"]["remote_service_id"] }.flatten
    return if lb_ids.blank?
    filters = {adapter_id: adapter_id, provider_id: lb_ids}
    ServiceDetail.where(filters).delete_all
    Services::Network::NetworkLoadBalancer::AWS.where(filters).synced_services.delete_all
    CloudTrailLog.where(adapter_id: adapter_id, :provider_id.in => lb_ids).delete_all
    #TODO: Uncomment when add support in environment
    # environmented_lbs = Services::Network::NetworkLoadBalancer::AWS.where(filters).in_environment.skip_deletion_states
    # unless environmented_lbs.blank?
    #   env_ids = environmented_lbs.map { |s| s.environment.try(:id)}.compact
    #   environmented_lbs.update_all(state: "removed_from_provider")
    #   environments = Environment.where(id: env_ids)
    #   environments.update_all(state: "unhealthy")
    # end
    update_cloud_trail_event_status(adapter_id, event_data.map { |event| event["eventID"] }, :success)
  end
end
