class ProviderWrappers::AWS::Networks::LoadBalancer < ProviderWrappers::AWS
  def destroy
    remote_service = get
    return if remote_service.blank?
    remote_service.destroy
    wait_for &method(:is_present_on_aws?)

    # even though the loadbalancer is deleted and not present on aws, while deleting dependant subnet it's throwing error
    # so sleeping for 30 seconds before deleting them
    sleep(30)

    remote_service
  end

  def get_listener(port)
    get.listeners.get(port)
  end

  def list_tags(id)
    begin
      agent.describe_tags(id).data[:body]["DescribeTagsResult"]["LoadBalancers"].find{ |v| v.is_a?(Hash) && v.keys.include?("Tags") }["Tags"]
    rescue Exception => e
      CSLogger.error("failed to get tags")
      {}
    end
  end

  def remove_listener(listener)
    remote_listener = get_listener(listener["lb_port"])
    return if remote_listener.blank?
    remote_listener.destroy
  end

  def add_listener(listener)
    get.listeners.create({
      instance_port: listener["instance_port"],
      instance_protocol: listener["instance_protocol"],
      lb_port: listener["lb_port"],
      protocol: listener["protocol"],
      ssl_id: listener["SSLCertificateId"]
    })
  end

  def get(name: service.provider_id)
    agent.load_balancers.get(name) if name.present?
  end

  def attach_subnets(subnet_ids:)
    get.attach_subnets(subnet_ids)
  end

  def detach_subnets(subnet_ids:)
    get.detach_subnets(subnet_ids)
  end

  def apply_security_groups(security_group_ids:)
    get.apply_security_groups(security_group_ids)
  end

  def configure_health_check(attributes:)
    health_check_target = "#{attributes[:ping_protocol]}:#{attributes[:ping_protocol_port]}"
    health_check_target = "#{health_check_target}/#{attributes[:ping_path]}" if attributes[:ping_path].present?
    get.configure_health_check({
      "Interval"=>attributes[:hcheck_interval], 
      "Target"=>health_check_target, 
      "HealthyThreshold"=>attributes[:healthy_threshold], 
      "Timeout"=>attributes[:response_timeout], 
      "UnhealthyThreshold"=>attributes[:unhealthy_threshold]
    })
  end

  def register_instances(instance_ids: )
    get.register_instances(instance_ids)
  end

  def deregister_instances(instance_ids: )
    get.deregister_instances(instance_ids)
  end

  def modify_load_balancer_attributes(attributes)
    agent.modify_load_balancer_attributes(service.name, {
      "CrossZoneLoadBalancing" => {
        "Enabled" => attributes[:cross_zone_load_balancing]
      },
      "ConnectionSettings" => {
        "IdleTimeout" => attributes[:connection_timeout]
      }
    })
  end

  def describe_attributes(id)
    elb_attributes = agent.describe_load_balancer_attributes(id).data[:body]["DescribeLoadBalancerAttributesResult"]["LoadBalancerAttributes"]
    cross_zone_load_balancing = (elb_attributes["CrossZoneLoadBalancing"]["Enabled"] rescue false)
    connection_timeout = (elb_attributes["ConnectionSettings"]["IdleTimeout"] rescue 0)
    connection_draining = (elb_attributes["ConnectionDraining"]["Enabled"] rescue false)
    connection_draining_timeout = (elb_attributes["ConnectionDraining"]["Timeout"] rescue 0)
    {
      "cross_zone_load_balancing" => cross_zone_load_balancing,
      "connection_timeout" => connection_timeout,
      "connection_draining" => connection_draining,
      "connection_draining_timeout" => connection_draining_timeout
    }
  end

  class << self

    def all(agent, filters = {})
      retries ||= 0
      retry_on_timeout {
        agent.load_balancers.all
      }
    rescue Fog::AWS::ELB::Throttled => e
     if e.message.include?("Rate exceeded")
       print "Excon Exeption:: => #{e.message}.Retrying ." if retries.eql?(0)
       if (retries += 1) < 3
         sleep 5
         print "."
         retry
       else
        CSLogger.error "Retry failed."
        CSLogger.error "Error : #{e.message}"
        CSLogger.error "BackTrace   : #{e.backtrace}"
       end
     else
      CSLogger.error "#{e.message}"
     end
    end

    def get(agent, lb_name)
      agent.load_balancers.get(lb_name) if lb_name.present?
    end
  end

end
