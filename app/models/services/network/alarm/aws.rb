class Services::Network::Alarm::AWS < Services::Network::Alarm
  # INTERFACES = [Services::Vpc, Services::Network::SecurityGroup::AWS, Services::Network::AutoScaling::AWS]
  include Services::ServiceHelpers::AWS

  store_accessor :data, :actions_enabled, :alarm_description, :comparison_operator, :evaluation_periods, :metric_name, :namespace, :period, :statistic, :threshold, :unit, :dimensions
  store_accessor :data, :alarm_actions # array of the names of the connected ASG policies

  def connected_to(service, via_services_map)
    # if interfaces_includes?(service)
    #   if self.provider_data["server_id"].present?
    #     server = (via_services_map[Services::Compute::Server::AWS.to_s]||[]).any?{|server| server.provider_id.eql?(self.provider_data["server_id"])}
    #     case service.class.to_s
    #     when Services::Vpc.to_s
    #       return server && server.provider_data["vpc_id"].eql?(service.provider_id)
    #     when Services::Network::AvailabilityZone.to_s
    #       return server && server.provider_data["availability_zone"].eql?(service.code)
    #     end
    #   end
    # end
    false
  end

  def provision
    remote_service = create_on_provider
    save_provider_data! remote_service.to_json, remote_service.id
  end

  def parent_services
    [Services::Vpc, Services::Network::SecurityGroup::AWS, Services::Network::Subnet::AWS, Services::Network::AutoScaling::AWS]
  end

  def get_dimensions_arr
    parent_auto_scalings
  end

  # loop over all connected ASG and find the policies, and return policy arn
  def get_alarm_actions
    CloudStreet.log "alarm_actions = #{parsed_alarm_actions.class} : #{parsed_alarm_actions.inspect}"
    parent_auto_scalings.map { |asg| asg.get_policy_arn(parsed_alarm_actions) }.flatten
  end

  private

  def parent_auto_scalings
    fetch_remote_services(Protocols::AutoScaling)
  end

  def create_on_provider
    CloudStreet.log "-------------------------------------Creating #{self.class.name} #{self.inspect}"
    asg_naming_convention = self.account.service_naming_defaults.auto_scaling.first.prefix_service_name
      parent_auto_scalings.each do |parent_auto_scaling|
        self.name = self.name.gsub(/#{asg_naming_convention}/, parent_auto_scaling.name)
        self.alarm_actions.each {|alarm_name| alarm_name.gsub!(/#{asg_naming_convention}/, parent_auto_scaling.name)}
        self.save!
      end  
    remote_service = ProviderWrappers::AWS::Networks::Alarm.new(service: self, agent: aws_cloudwatch_agent).create
    CloudStreet.log "-------------------------------------Created #{remote_service.inspect}"
    remote_service
  end

  def parsed_alarm_actions
    parsed_alarm = alarm_actions.is_a?(String) ? JSON.parse(alarm_actions) : alarm_actions
    if account.naming_convention_enabled?
      asg_naming_convention = self.account.service_naming_defaults.auto_scaling.first.prefix_service_name
      parent_auto_scalings.each do |parent_auto_scaling|
        self.name = self.name.gsub(/#{asg_naming_convention}/, parent_auto_scaling.name)
        parsed_alarm.each {|alarm_name| alarm_name.gsub!(/#{asg_naming_convention}/, parent_auto_scaling.name)}
        self.save!
      end         
    end
    parsed_alarm
  end
end
