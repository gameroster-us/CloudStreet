class AWSRemoteServiceObject::LoadBalancer < Struct.new(:provider_data,:provider_id, :subnet_ids, :security_groups, :listener_descriptions, :instances, :availability_zones, :Policies, :health_check, :source_group, :BackendServerDescriptions, :vpc_id, :hosted_zone_name_id, :scheme, :dns_name, :created_at, :tags, :listeners, :instance_health, :provider_created_at)
  def format_listener_from_remote(listener)
    {
      "Listener" => {
        "instance_port" => listener["InstancePort"],
        "instance_protocol" => listener["InstanceProtocol"],
        "lb_port" => listener["LoadBalancerPort"],
        "protocol" => listener["Protocol"],
        "SSLCertificateId" => listener["SSLCertificateId"]
      }
    }
  end

  def get_formatted_listeners
    listener_descriptions.collect do |listener|
      format_listener_from_remote(listener["Listener"])
    end
  end

  def get_attributes_for_service_table
    formatted_listeners = get_formatted_listeners
    {
      name: provider_id,
      scheme: scheme,
      dns_name: dns_name,
      hcheck_interval: health_check["Interval"],
      response_timeout: health_check["Timeout"],
      healthy_threshold: health_check["HealthyThreshold"],
      unhealthy_threshold: health_check["UnhealthyThreshold"],
      ping_protocol: health_check["Target"].split(":").first,
      ping_protocol_port: health_check["Target"].split(":").last.split("/").first,
      ping_path: health_check["Target"].split(":").last.split("/").last,
      state: "running",
      availability_zones: try(:availability_zones).join(','),
      category: "classic",
      tags: tags,
      cross_zone_load_balancing: try(:cross_zone_load_balancing),
      connection_timeout: (try(:connection_settings_idle_timeout) || try(:connection_timeout)),
      connection_draining: try(:connection_draining),
      connection_draining_timeout: try(:connection_draining_timeout),
      listeners: formatted_listeners,
      instance_health: try(:instance_health),
      provider_id: provider_id,
      provider_data: provider_data,
      vpc_id: vpc_id,
      provider_created_at: created_at,
      service_tags: Services::ServiceHelpers::AWS.get_service_tags(tags)
    }
  end

  def self.parse_from_json(data)
    new(
      data,
      data["id"],
      data["subnet_ids"],
      data["security_groups"],
      data["ListenerDescriptions"],
      data["instances"],
      data["availability_zones"],
      data["Policies"],
      data["health_check"],
      data["source_group"],
      data["BackendServerDescriptions"],
      data["vpc_id"],
      data["hosted_zone_name_id"],
      data["scheme"],
      data["dns_name"],
      data["created_at"],
      data["tags"]
    )
  end
end
