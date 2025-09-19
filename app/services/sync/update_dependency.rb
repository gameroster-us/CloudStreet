module Sync::UpdateDependency

  def update_vpc_attrs
    vpcs = YAML.load(File.open("#{@root_path}/vpc.yml")) || []
    internet_gateways = YAML.load(File.open("#{@root_path}/internet_gateway.yml")) || []
    vpc_id_mapper = internet_gateways.inject({}){|mapper, ig| mapper.merge!({(ig.attachment_set||{})["vpcId"] => ig.provider_id}) unless ig.attachment_set["vpcId"].nil?; mapper }
    vpcs.each do |vpc|
      if vpc_id_mapper[vpc.provider_id].present?
        vpc.internet_attached = true
        vpc.internet_gateway_id = vpc_id_mapper[vpc.provider_id]
      end
    end
    File.open("#{@root_path}/vpc.yml", "w+") {|f| f.write vpcs.to_yaml }
  rescue Errno::ENOENT => e
    CSLogger.error("#{e.message} YML file not found.")
  end

  def update_server_volume_attrs
    servers = YAML.load(File.open("#{@root_path}/server.yml")) || []
    volumes = YAML.load(File.open("#{@root_path}/volume.yml")) || []
    elastic_ip = YAML.load(File.open("#{@root_path}/elastic_ip.yml")) || []
    auto_scaling = YAML.load(File.open("#{@root_path}/auto_scaling.yml")) || []
    server_ids = servers.pluck(:provider_id).uniq
    compute_agent = @adapter.connection(@region.code)
    server_statuses = []
    server_ids.each_slice(100) do |limited_server_ids|
      response = ProviderWrappers::AWS::Computes::Server.get_instance_statuses(compute_agent, limited_server_ids).try(:body) rescue []
      server_statuses.concat(response["instanceStatusSet"] || []) unless response.blank?
    end
    servers.each do |server|
      server.status_checks = [(server_statuses||[]).find { |status| status["instanceId"].eql?(server.provider_id) }]
      volume_ids = server.block_device_mapping.map{ |bdm| bdm["volumeId"] }
      volumes.each do |volume|
        next unless volume_ids.include?(volume.provider_id)
        volume.vpc_id = server.vpc_id
        volume.server_name = server.tags["Name"]||server.provider_id
      end
    end
    elastic_ip.each do |eip|
      next if eip.server_id.blank?
      server = servers.find { |server| server.provider_id == eip.server_id }
      server.elastip_ip_list ||= []
      server.elastip_ip_list << eip.public_ip
      eip.vpc_id = server.vpc_id
    end
    asg_instance_ids = auto_scaling.map(&:instance_ids).flatten.compact
    servers.each { |server| server.is_asg_server = true if asg_instance_ids.include?(server.provider_id) }

    File.open("#{@root_path}/server.yml", "w+") {|f| f.write servers.to_yaml }
    File.open("#{@root_path}/volume.yml", "w+") { |f| f.write volumes.to_yaml  }
    File.open("#{@root_path}/elastic_ip.yml", "w+") { |f| f.write elastic_ip.to_yaml }
  rescue Errno::ENOENT => e
    CSLogger.error("#{e.message} YML file not found.")
  end

  def update_lc_attrs
    lcs = YAML.load(File.open("#{@root_path}/auto_scaling.yml")) || []
    subnets = YAML.load(File.open("#{@root_path}/subnet.yml")) || []
    auto_scaling_configurations = YAML.load(File.open("#{@root_path}/auto_scaling_configuration.yml")) || []
    lc_vpc_map = lcs.each_with_object({}) do |auto_scaling, lc_vpc_map|
      subnet_ids = auto_scaling.subnet_ids
      next if subnet_ids.blank?
      subnet = subnets.find { |subnet| subnet_ids.include?(subnet.provider_id) }
      next if subnet.blank?
      auto_scaling.vpc_id = subnet.vpc_id
      lc_vpc_map[auto_scaling.launch_configuration_name] = subnet.vpc_id  unless auto_scaling.launch_configuration_name.blank?
    end
    auto_scaling_configurations.each do |lc|
      lc.vpc_id = lc_vpc_map[lc.provider_id]
    end unless lc_vpc_map.blank?
    File.open("#{@root_path}/auto_scaling_configuration.yml", "w+") {|f| f.write auto_scaling_configurations.to_yaml }
    File.open("#{@root_path}/auto_scaling.yml", "w+") { |f| f.write lcs.to_yaml }
  rescue Errno::ENOENT => e
    CSLogger.error("#{e.message} YML file not found.")
  end

  def update_rds_attrs
    all_rds = YAML.load(File.open("#{@root_path}/rds.yml")) || []
    all_rds.each do |rds|
      next if rds.db_subnet_group_name.blank?
      rds.vpc_id = SubnetGroup.where(@options.except(:aws_account_id)).find_by_name(rds.db_subnet_group_name).try(:provider_data).try(:[], 'vpc_id')
    end
    File.open("#{@root_path}/rds.yml", "w+") {|f| f.write all_rds.to_yaml }
  rescue Errno::ENOENT => e
    CSLogger.error("#{e.message} YML file not found.")
  end

  def update_lb_tags
    lb_agent = ProviderWrappers::AWS::Networks::LoadBalancer.elb_agent(@adapter, @region.code)
    load_balancers = YAML.load(File.open("#{@root_path}/load_balancer.yml")) || []
    load_balancers.each do |lb|
      lb.tags = lb_agent.describe_tags(lb.provider_id).body["DescribeTagsResult"]["LoadBalancers"][0]["Tags"] rescue {}
    end
    File.open("#{@root_path}/load_balancer.yml", "w+") {|f| f.write load_balancers.to_yaml }
  rescue Errno::ENOENT => e
    CSLogger.error("#{e.message} YML file not found.")
  end

  def update_rds_tags
    rds_agent = ProviderWrappers::AWS::Databases::Rds.rds_agent(@adapter, @region.code)
    all_rds = YAML.load(File.open("#{@root_path}/rds.yml")) || []
    all_rds.each do |rds|
      rds.tags = rds_agent.list_tags_for_resource(rds.provider_id).body["ListTagsForResourceResult"]["TagList"] rescue {}
    end
    File.open("#{@root_path}/rds.yml", "w+") {|f| f.write all_rds.to_yaml }
  rescue Errno::ENOENT => e
    CSLogger.error("#{e.message} YML file not found.")
  end

  def update_asg_policy
    all_auto_scaling = YAML.load(File.open("#{@root_path}/auto_scaling.yml")) || []
    asg_ids = all_auto_scaling.pluck(:provider_id)
    asg_agent  = ProviderWrappers::AWS::Networks::AutoScaling.autoscalling_agent(@adapter, @region.code)
    policies   = asg_agent.policies.all rescue [] unless asg_ids.blank?
    activities = asg_agent.describe_scaling_activities.body["DescribeScalingActivitiesResult"]["Activities"] rescue [] unless asg_ids.blank?
    all_auto_scaling.each do |auto_scaling|
      auto_scaling.policies = JSON.parse(policies.select { |policy| policy.auto_scaling_group_name.eql?(auto_scaling.provider_id) }.to_json)
      auto_scaling.activity = activities.select { |activity| activity["AutoScalingGroupName"].eql?(auto_scaling.provider_id) }
    end
    File.open("#{@root_path}/auto_scaling.yml", "w+") {|f| f.write all_auto_scaling.to_yaml }
  rescue Errno::ENOENT => e
    CSLogger.error("#{e.message} YML file not found.")
  end

  def update_lb_attrs
    application_lbs = YAML.load(File.open("#{@root_path}/application_load_balancer.yml")) || []
    network_lbs = YAML.load(File.open("#{@root_path}/network_load_balancer.yml")) || []
    application_lbs.each do |load_balancer|
      update_extra_attributes_for_nw_app_lbs(load_balancer)
    end

    network_lbs.each do |load_balancer|
      update_extra_attributes_for_nw_app_lbs(load_balancer)
    end
    File.open("#{@root_path}/application_load_balancer.yml", "w+") {|f| f.write application_lbs.to_yaml }
    File.open("#{@root_path}/network_load_balancer.yml", "w+") {|f| f.write network_lbs.to_yaml }
  rescue Errno::ENOENT => e
    CSLogger.error("#{e.message} YML file not found.")
  end

  def update_extra_attributes_for_nw_app_lbs(load_balancer)
    begin
      v2_elb_client = @adapter.connection_v2_elb_client(@region.code)
      resp = v2_elb_client.describe_tags({resource_arns: [load_balancer.load_balancer_arn]})
      load_balancer.provider_id = load_balancer.load_balancer_name
      load_balancer.tags = resp.tag_descriptions[0].tags.blank? ? {} : resp.tag_descriptions[0].tags.inject([]) { |h, v| h << { v['key'] => v['value']} }.inject(:merge)
      res = v2_elb_client.describe_listeners({load_balancer_arn: load_balancer.load_balancer_arn}).to_h
      load_balancer.listeners = res[:listeners].blank? ? [] : res[:listeners]
      target_groups_res = v2_elb_client.describe_target_groups({load_balancer_arn: load_balancer.load_balancer_arn}).to_h
      load_balancer.target_groups = target_groups_res[:target_groups].blank? ? [] : target_groups_res[:target_groups]
      lb_attrs = v2_elb_client.describe_load_balancer_attributes({load_balancer_arn: load_balancer.load_balancer_arn}).to_h
      set_lb_attributes(load_balancer, lb_attrs)
    rescue Aws::ElasticLoadBalancingV2::Errors, StandardError => e
      if e.code.eql?("AccessDenied")
        CSLogger.error "=======#{e.message} Access denied for #{@adapter.name} in #{@region.code}===="
      else
        CSLogger.error e.message
        CSLogger.error e.backtrace
      end
    end
  end

  def set_lb_attributes(load_balancer, lb_attrs)
    lb_attrs[:attributes].each do |lb|
      if lb[:key].eql?("load_balancing.cross_zone.enabled") && load_balancer.type.eql?("network")
        load_balancer.load_balancing_cross_zone_enabled = lb[:value]
      elsif lb[:key].eql?("access_logs.s3.enabled")
        load_balancer.access_logs_s3_enabled = lb[:value]
      elsif lb[:key].eql?("access_logs.s3.bucket")
        load_balancer.access_logs_s3_bucket = lb[:value]
      elsif lb[:key].eql?("access_logs.s3.prefix")
        load_balancer.access_logs_s3_prefix = lb[:value]
      elsif lb[:key].eql?("idle_timeout.timeout_seconds") && load_balancer.type.eql?("application")
        load_balancer.idle_time_out_seconds = lb[:value]
      elsif lb[:key].eql?("deletion_protection.enabled")
        load_balancer.deletion_protection_enabled = lb[:value]
      elsif lb[:key].eql?("routing.http2.enabled") && load_balancer.type.eql?("application")
        load_balancer.routing_http2_enabled = lb[:value]
      elsif lb[:key].eql?("routing.http.drop_invalid_header_fields.enabled") && load_balancer.type.eql?("application")
        load_balancer.drop_invalid_header_fields_enabled = lb[:value]
      end
    end
    return load_balancer
  end

  def update_server_additional_data
    servers = YAML.load(File.open("#{@root_path}/server.yml")) || []
    servers.each do |server|
      begin
        agent = ProviderWrappers::AWS::Computes::Server.compute_agent(@adapter, @region.code)
        api_termination = agent.describe_instance_attribute(server.provider_id, "disableApiTermination")
        shutdown_behaviour = agent.describe_instance_attribute(server.provider_id, "instanceInitiatedShutdownBehavior")
        server.instance_initiated_shutdown_behavior = shutdown_behaviour.data[:body]["instanceInitiatedShutdownBehavior"]
        server.disable_api_termination = api_termination.data[:body]["disableApiTermination"]
        server.associate_public_ip = !server.public_ip_address.blank?
      rescue Exception => e
        CSLogger.error e.message
        CSLogger.error e.backtrace
      end
    end
    File.open("#{@root_path}/server.yml", "w+") {|f| f.write servers.to_yaml }
  rescue Errno::ENOENT => e
    CSLogger.error("#{e.message} YML file not found.")
  end

  def update_eks_attrs
    eks_clusters = YAML.load(File.open("#{@root_path}/eks.yml")) || []
    eks_clusters.each do |eks_cluster|
      CSLogger.info "Adding nodegroups and fargate_profiles information for EKS : #{eks_cluster.name} of adapter #{@adapter.name}"
      begin
        nodegroup_resp = AWSRecords::Container::EKS::AWS.get_node_groups(@adapter, @region.code, eks_cluster.name)
        fargate_resp = AWSRecords::Container::EKS::AWS.get_fargate_profiles(@adapter, @region.code, eks_cluster.name)
        if nodegroup_resp.status.eql?(:success) && fargate_resp.status.eql?(:success)
          nodegroups = nodegroup_resp.data
          fargate_profiles = fargate_resp.data
          eks_cluster.provider_data[:nodegroups] = nodegroups.map { |ng| ng.slice(:nodegroup_name, :status, :health) }
          eks_cluster.provider_data[:fargate_profiles] = fargate_profiles.map { |fargate| fargate.slice(:fargate_profile_name, :status) }
          eks_cluster.provider_data[:is_unused] = (nodegroups.blank? && fargate_profiles.blank?)
          eks_cluster.provider_data[:is_unhealthy] = nodegroups.any? { |ng| ng[:health][:issues].present? } if nodegroups.present?
        end
      rescue StandardError => e
        CSLogger.error "Error occurred while updating dependancies of Amazon EKS : === #{e.message}"
        next
      end
    end
    File.open("#{@root_path}/eks.yml", 'w+') { |f| f.write eks_clusters.to_yaml }
  rescue Errno::ENOENT => e
    CSLogger.error("#{e.message} YML file not found.")
  end
end
