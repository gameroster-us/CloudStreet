class CloudTrail::Processors::Server

  include CloudTrail::Utils::ProcessorHelper

  def self.call(adapter, region_code_map, *args, &block)
    service_type = args[0]["service_type"]
    group_events = args[0]["group_events"]
    group_events.inject([]) do |objects, event|
      obj = self.new(adapter, region_code_map[event["region_code"]], event['event_name'], event["event_data"], service_type)
      obj.extend "CloudTrail::Events::Server::#{event['event_name']}".constantize
      yield(obj)
    end
  end

  def self.update_services(service_type, adapter_id, region_id, modified_events)
    sync_modified_events(service_type, adapter_id, region_id, modified_events) do |service, events|
      existing_state = service.state
      connection_change = {}
      events.each do |event|
        event["attributes"].each do |key, value|
          if key.eql?("launch_script")
            agent = service.adapter.compute_client(event["region_code"])
            value = ProviderWrappers::AWS::Computes::Server.get_instance_attribute(agent, service.provider_id, "userData") rescue nil
            service.send("#{key}=", value)
            service.provider_data["user_data"] = value
          # This is only added for delete on termination true for their volume
          elsif key.eql?("block_device_mapping")
            # volumes = ser.provider_data['block_device_mapping']
            # ser.provider_data['block_device_mapping'] = volumes
            CTLog.info "=====> Before In blockDeviceMapping #{key} #{value} #{service}"
            value.each do |val|
              if val.key?('deviceName') && val.key?('ebs') && val['ebs'].key?('deleteOnTermination')
                # For service volume
                service.provider_data['block_device_mapping'].each do |vol|
                  next unless vol['deviceName'].eql?(val['deviceName'])

                  vol.merge!(val['ebs'])
                end

                # For service attached volume
                service.attached_volumes.each do |attached_vol|
                  next unless attached_vol.device.eql?(val['deviceName'])

                  attached_vol.delete_on_termination = attached_vol.provider_data['delete_on_termination'] = val['ebs']['deleteOnTermination']
                  attached_vol.save
                end
              end
            end
            CTLog.info "=====> After In blockDeviceMapping #{key} #{value} #{service}"
          else
            service.send("#{key}=", value)
            service.provider_data[key] = value if service.provider_data.has_key?(key)
          end
        end
      end
      service.store_ram_size
      service.calculate_up_time if existing_state.eql?("running") && service.state.eql?("stopped")
      next service, connection_change
    end
  end

  def self.remove_services(adapter_id, event_data)
    instance_ids = event_data.map { |event| event["attributes"]["remote_service_id"] }.flatten
    return if instance_ids.blank?

    filters = {adapter_id: adapter_id, provider_id: instance_ids}

    services = Services::Compute::Server::AWS.includes(:environment).where(filters).skip_deletion_states
    remove_from_solr(services) unless services.blank?
    services.each do |server|
      if server.environment.present?
        server.removed_from_provider!
        server.environment.update(state: 'unhealthy')
      else
        server.remove_from_cloudstreet
      end
    end
    ServiceDetail.where(filters).delete_all
    remove_scanned_data(adapter_id, instance_ids)
    CloudTrailLog.where(adapter_id: adapter_id, :provider_id.in => instance_ids).delete_all
  	update_cloud_trail_event_status(adapter_id ,event_data.map { |event| event["eventID"] }, :success)
  rescue StandardError => e
    CTLog.error e.message
    CTLog.error e.backtrace
  end

  def initialize(adapter, region, *args)
    @adapter = adapter
    @region = region
    @event_name = args[0]
    @events = args[1]
    @service_type = args[2]
    @action = if @event_name == "RunInstances"
                "create"
              elsif @event_name == "TerminateInstances" || @event_name == "BidEvictedEvent"
                "delete"
              else
                "modify"
              end
  end

  def get_servers_for_state(event, states)
    instances = event["requestParameters"]["instancesSet"]["items"] rescue []
    return instances if instances.blank?

    instances.inject([]) do |servers, server|
      response = event["responseElements"]["instancesSet"]["items"].detect { |res| res["instanceId"] == server["instanceId"] }
      if server["instanceId"] == response["instanceId"] && states.include?(response["currentState"]["name"])
        servers << {"instanceId" => server["instanceId"], "state" => get_server_state(response["currentState"]["name"])}
      end
      servers
    end
  end

  private

  def get_server_state(state)
    case state
    when "pending", "starting", "running" then "running"
    when "stopped", "stopping" then "stopped"
    when "shutting-down", "terminated" then "removed_from_provider"
    end
  end

end
