class ProviderWrappers::AWS::Networks::SecurityGroup < ProviderWrappers::AWS
  class << self
    def all(agent, filters = {})
      options = {}
      options.merge!({"vpc-id"=>filters[:vpc_id]}) if filters[:vpc_id].present?
      options.merge!({"group-name" => filters[:group_names]})if filters[:group_names].present?
      options.merge!({"group-id" => filters[:group_ids]})if filters[:group_ids].present?
      retry_on_timeout {
        return agent.security_groups.all(options)
      }
    end

    def get_by_id(agent, sg_id)
      agent.security_groups.get_by_id(sg_id) if sg_id
    end
  end
end
