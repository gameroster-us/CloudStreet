class Services::Network::ApplicationLoadBalancer::AWS < Service

  include Services::ServiceHelpers::AWS
  include Behaviors::Costable::Amazon::ApplicationLoadBalancer
  store_accessor :data, :region, :dns_name, :scheme, :category, :arn, :canonical_hosted_zone_id, :category, :availability_zones, :ip_address_type, :security_groups, :subnet_ids, :listeners, :idle_time_out_seconds, :deletion_protection_enabled, :access_logs_s3_enabled, :access_logs_s3_bucket, :access_logs_s3_prefix, :routing_http2_enabled, :drop_invalid_header_fields_enabled, :listeners, :target_groups, :health_check_protocol, :health_check_port, :health_check_enabled, :hcheck_interval, :response_timeout, :healthy_threshold, :unhealthy_threshold, :health_check_path, :matcher, :tags, :service_tags

  INTERFACES = [Services::Vpc, Services::Network::Subnet::AWS,  Services::Network::SecurityGroup::AWS, Services::Compute::Server::AWS].freeze

  def protocol
    "Protocols::ApplicationLoadBalancer"
  end

  def properties
    [

      {
        form_options: {
          type: "text",
          unitLabel: "seconds"
        },
        name: "hcheck_interval",
        title: "Health Check Interval",
        value: "30",
        validation: '/^[0-9]*$/'
      },
      {
        form_options: {
          type: "text",
          unitLabel: "seconds"
        },
        name: "response_timeout",
        title: "Health Check TimeOut Seconds",
        value: "5",
        validation: '/^[0-9]*$/'
      },
      {
        form_options: {
          type: "range",
          min: "2",
          max: "10",
          step: "1"
        },
        name: "unhealthy_threshold",
        title: "Unhealthy Threshold Count",
        value: "4"
      },
      {
        form_options: {
          type: "range",
          min: "2",
          max: "10",
          step: "1"
        },
        name: "healthy_threshold",
        title: "Healthy Threshold Count",
        value: "9"
      }
    ]
  end

  def depends
    [
      { name: "frontend", protocol: Protocols::IP, limit: 1, max_connections: 2 },
      { name: "subnet", protocol: Protocols::Subnet }
    ]
  end

  def provides
    [
      { name: "ApplicationLoadBalancer", protocol: Protocols::ApplicationLoadBalancer, limit: 1, max_connections: 1024 }
    ]
  end

  def connected_to(service, _via_services_map)
    if interfaces_includes?(service)
      case service.class.to_s
      when Services::Vpc.to_s
        return is_connected_to_vpc?(service)
      when Services::Network::SecurityGroup::AWS.to_s
        return is_connected_to_security_group?(service)
      when Services::Network::Subnet::AWS.to_s
        return is_connected_to_subnet?(service)
      end
    end
    false
  end

  def is_connected_to_vpc?(service)
    if provider_data.blank?
      connected_via_interface_to(service)
    else
      parsed_provider_data["vpc_id"].eql?(service.provider_id)
    end
  end

  def is_connected_to_security_group?(service)
    if provider_data.blank?
      connected_via_interface_to(service)
    else
      (parsed_provider_data["security_groups"] || []).include?(service.provider_id)
    end
  end

  def is_connected_to_subnet?(service)
    if provider_data.blank?
      connected_via_interface_to(service)
    else
      subnet_group_ids = parsed_provider_data["availability_zones"].map { |h| h.slice("subnet_id").values }.flatten
      subnet_group_ids.include?(service.provider_id)
    end
  end

  def set_parent_container_id
    fetch_first_remote_service("Protocols::Vpc").try(:id)
  end

  def check_and_mark_unused
    unless self.provider_data.blank?
      if self.provider_data["instances"].blank?
        update_unused(true)
        return
      end

      unless self.instance_health.blank?
        state = instance_health.map { |h| h["State"] }.uniq
        if state.size == 1 && state.first == "OutOfService"
          update_unused(true)
          return
        else
          update_unused(false)
        end
      end
    end

    unless self.data.blank?
      security_group_services = self.fetch_remote_services("Protocols::SecurityGroup")

      unused = false
      security_group_services.each do |security_group|
        if security_group.data["ip_permissions_egress"].blank? && security_group.data["ip_permissions_ingress"].blank?
          unused = true
        end
      end
      update_unused(unused)
    end
  end

  def update_unused(value=true)
    begin
      value = value ? 1 : 0
      self.data = self.data.blank? ? {"unused" => value} : self.data.merge({"unused" => value})
      self.save
    rescue Exception => e
      CloudStreet.log e.message
      CloudStreet.log e.backtrace
    end
  end

  def validate_for_termination
    CloudStreet.log "--------------------validating before terminating application lb-------------------------"
    if self.deletion_protection_enabled.eql?("true")
      self.errors.add(:deletion_protection_enabled, I18n.t('termination_validation.error_msgs.deletion_protection_enabled', service_name: self.name))
    end
  end

  def terminate_service(params={})
    region_code = Region.find(self.region_id).code
    v2_elb_client = adapter.connection_v2_elb_client(region_code)
    v2_elb_client.delete_load_balancer({load_balancer_arn: self.provider_data["load_balancer_arn"]})
    CloudStreet.log "-------------------------------------Terminated(#{self.type}) => #{self.name}"
  end

end
