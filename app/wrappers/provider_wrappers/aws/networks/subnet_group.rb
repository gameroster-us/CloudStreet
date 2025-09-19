class ProviderWrappers::AWS::Networks::SubnetGroup < ProviderWrappers::AWS
  def get
    provider_id = service.provider_id
    CSLogger.info "------------------------subnet_group_id----------------#{provider_id}"
    agent.subnet_groups.get(provider_id) if provider_id.present?
  end
  alias_method :get_subnet_group, :get

  def create(subnet_group_attrs)
    CSLogger.info "-------creating-----------------subnet_group_attrs----------------#{subnet_group_attrs.inspect}"
    agent.subnet_groups.create(subnet_group_attrs)
  end

  def modify(subnet_group_attrs)
    CSLogger.info "-------modifying-----------------subnet_group_attrs----------------#{subnet_group_attrs.inspect}"
    agent.modify_db_subnet_group(subnet_group_attrs)
  end


  def terminate
    get.try :destroy
  end

  class << self
    def all(agent, filters = {})
      retry_on_timeout {
        return agent.subnet_groups.all
      }
    end
  end
end
