class CloudTrail::Processors::LoadBalancer
  include CloudTrail::Utils::ProcessorHelper

  def self.call(adapter, region_code_map, *args)
    service_type = args[0]["service_type"]
    group_events = args[0]["group_events"]
    group_events.each do |event|
      obj = new(adapter, region_code_map[event["region_code"]], event["event_data"], service_type, event['event_name'])
      obj.extend "CloudTrail::Events::LoadBalancer::#{event['event_name']}".constantize
      yield(obj)
    end
  end

  def initialize(adapter, region, *args)
    @adapter = adapter
    @region = region
    @event_name = args[2]
    @events = args[0]
    @service_type = args[1]
    @action = if @event_name == "CreateLoadBalancer"
      "create"
    elsif @event_name == "DeleteLoadBalancer"
      "delete"
    else
      "modify"
    end
  end

  def self.update_services(service_type, adapter_id, region_id, modified_events)
    sync_modified_events(service_type, adapter_id, region_id, modified_events) do |service, events|
      connection_change = {}
      attached_detached_attributes = {}
      environment_id = service.environment.try(:id)
      service_ids = []
      removed_instance_ids = []
      events.each do |event|
        event["attributes"].each do |key, value|
          case key
          when "instances"
            if value["action"].eql?("add")
              value = ((service.provider_data["instances"] || []) + value["instance_ids"]).uniq
            elsif value["action"].eql?("delete")
              removed_instance_ids.concat(value["instance_ids"] || [])
              value = ((service.provider_data["instances"] || [])).reject { |instance_id| (value["instance_ids"] || []).include?(instance_id) }
            end
          when "subnet_ids"
            if value["action"].eql?("add")
              value = ((service.provider_data["subnet_ids"] || []) + value["subnet_ids"]).uniq
            elsif value["action"].eql?("delete")
              value = ((service.provider_data["subnet_ids"] || [])).reject { |subnet_id| (value["subnet_ids"] || []).include?(subnet_id) }
            end
          when "health_check"
            service.hcheck_interval     = value["Interval"]
            service.response_timeout    = value["Timeout"]
            service.unhealthy_threshold = value["UnhealthyThreshold"]
            service.healthy_threshold   = value["HealthyThreshold"]
            target_value                = value["Target"]
            service.ping_protocol       = target_value.split(":").first rescue nil
            service.ping_protocol_port  = target_value.split(":").last.split("/").first rescue nil
            service.ping_path           = target_value.split(":").last.split("/").last rescue nil
          when "ListenerDescriptions"
            if value["action"].eql?("add")
              service.listeners ||= []
              service.provider_data[key] ||= []
              obj = AWSRemoteServiceObject::LoadBalancer.new
              obj.listener_descriptions = value["listeners"]
              service.listeners = service.listeners.concat(obj.get_formatted_listeners)
              service.provider_data[key] = service.provider_data[key].concat(value["listeners"])
            elsif value["action"].eql?("delete")
              deleted_ports = value["loadBalancerPorts"] || []
              service.listeners = (service.listeners || []).reject { |listener| deleted_ports.include?(listener["Listener"] && listener["Listener"]["lb_port"]) }
              service.provider_data[key] = (service.provider_data[key] || []).reject { |listener| deleted_ports.include?(listener["Listener"] && listener["Listener"]["LoadBalancerPort"]) }
            end
            key = "listeners"
          else
            service.send("#{key}=", value) if !["subnet_ids", "security_groups", "instances", "health_check"].include?(key) && service.respond_to?(key.to_sym)
          end
          service.provider_data[key] = value if service.provider_data.key?(key)
          attached_detached_attributes.merge!({key => value}) if ["subnet_ids", "security_groups", "instances"].include?(key)
        end
      end
      removed_instance_ids -= (service.provider_data["instances"] || [])
      remove_server_connections(environment_id, service, removed_instance_ids) unless removed_instance_ids.blank?
      attached_detached_attributes.each { |key,value| service_ids += update_connected_services(service,environment_id,key,value) }
      connection_change[environment_id] = [service.id] + service_ids
      next service, connection_change
    end
  end

  class << self

    def remove_server_connections(environment_id, service, removed_instance_ids)
      lb_interface_id  = service.interfaces.of_type("Protocols::LoadBalancer").first.try(:id)
      grouped_services = Services::Compute::Server::AWS.includes(:environment).where(adapter_id: service.adapter_id, region_id: service.region_id, provider_id: removed_instance_ids).active_services.group_by { |s| s.environment.try(:id) }
      (grouped_services[environment_id] || []).each do |server|
        server_lb_interface_id = server.interfaces.of_type("Protocols::LoadBalancer").first.try(:id)
        Connection.where(interface_id: server_lb_interface_id, remote_interface_id: lb_interface_id).delete_all if !server_lb_interface_id.blank? && !lb_interface_id.blank?
      end
    end

    def update_connected_services(service,environment_id,key,value)
      service_ids          = []

      case key
      when "instances"
        service_ids += get_dependent_servers(environment_id,service.adapter_id,service.region_id, value)
      when "security_groups"
        service_ids += get_dependent_security_groups(environment_id,service.adapter_id,service.region_id, value)
      when "subnet_ids"
        service_ids += get_dependent_subnets(environment_id,service.adapter_id,service.region_id, value)
      end
      service_ids = service_ids.uniq
      unless environment_id.blank?
        Service.where(id: service_ids).update_all(vpc_id: service.vpc_id)
        service_ids.each do |service_id|
          EnvironmentService.find_or_create_by(service_id: service_id) do |environment_service|
            environment_service.environment_id = environment_id
          end
        end
      end

      return service_ids
    end

    def get_dependent_servers(environment_id, adapter_id, region_id, provider_ids)
      return [] if provider_ids.blank?
      grouped_services = Services::Compute::Server::AWS.includes(:environment).where(adapter_id: adapter_id, region_id: region_id, provider_id: provider_ids).active_services.group_by { |s| s.environment.try(:id) }
      service_ids = (grouped_services[nil].try(:pluck,:id) || [])
      service_ids += (grouped_services[environment_id].try(:pluck,:id) || []) unless environment_id.blank?
      unless environment_id.blank?
        Services::Compute::Server::AWS.where(id: service_ids).each do |server|
          service_ids += (server.attached_volumes.pluck(:id) + server.attached_network_interfaces.pluck(:id))
          service_ids += get_dependent_security_groups(environment_id,adapter_id,region_id, server.attached_security_groups.pluck(:provider_id))
          service_ids += get_dependent_subnets(environment_id,adapter_id,region_id, server.attached_subnets.pluck(:provider_id))
        end
        service_ids += Services::Network::ElasticIP::AWS.where(adapter_id: adapter_id, region_id: region_id).find_by_server_ids(provider_ids).pluck(:id)
      end
      return service_ids
    end

    def get_dependent_security_groups(environment_id,adapter_id,region_id, provider_ids)
      return [] if provider_ids.blank?
      services = Services::Network::SecurityGroup::AWS.includes(:environment).where(adapter_id: adapter_id, region_id: region_id, provider_id: provider_ids).where(environments: {id: environment_id}).active_services
      service_ids = services.pluck(:id)
      missing_services = (provider_ids || []) - services.pluck(:provider_id)
      service_ids_to_move = SecurityGroups::AWS.where(adapter_id: adapter_id, region_id: region_id, group_id: missing_services, state: "available").collect do |sg|
        sg_new = sg.get_service_table_object
        sg_new.id = SecureRandom.uuid
        sg_new.save
        sg_new.id
      end
      return service_ids + service_ids_to_move
    end

    def get_dependent_subnets(environment_id,adapter_id,region_id, provider_ids)
      return [] if provider_ids.blank?
      services = Services::Network::Subnet::AWS.includes(:environment).where(adapter_id: adapter_id, region_id: region_id, provider_id: provider_ids).where(environments: {id: environment_id}).active_services
      service_ids = services.pluck(:id)
      missing_services = (provider_ids || []) - services.pluck(:provider_id)
      service_ids_to_move = Subnets::AWS.where(adapter_id: adapter_id, region_id: region_id, provider_id: missing_services, state: "available").collect do |sg|
        sg_new = sg.get_service_table_object
        sg_new.id = SecureRandom.uuid
        sg_new.save
        sg_new.id
      end
      return service_ids + service_ids_to_move
    end



    def remove_services(adapter_id, event_data)
      lb_ids = event_data.map { |event| event["attributes"]["remote_service_id"] }.flatten
      return if lb_ids.blank?
      filters = {adapter_id: adapter_id, provider_id: lb_ids}
      Services::Network::LoadBalancer::AWS.where(filters).synced_services.delete_all
      ServiceDetail.where(filters).delete_all
      environmented_lbs = Services::Network::LoadBalancer::AWS.where(filters).in_environment.skip_deletion_states
      unless environmented_lbs.blank?
        env_ids = environmented_lbs.map { |s| s.environment.try(:id)}.compact
        environmented_lbs.update_all(state: "removed_from_provider")
        environments = Environment.where(id: env_ids)
        environments.update_all(state: "unhealthy")
      end
      remove_scanned_data(adapter_id, lb_ids)
      CloudTrailLog.where(adapter_id: adapter_id, :provider_id.in => lb_ids).delete_all
      update_cloud_trail_event_status(adapter_id, event_data.map { |event| event["eventID"] }, :success)
    end
  end
end
