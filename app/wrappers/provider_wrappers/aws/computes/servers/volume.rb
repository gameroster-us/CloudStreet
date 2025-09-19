class ProviderWrappers::AWS::Computes::Servers::Volume < ProviderWrappers::AWS
  class << self
    def all(agent, filters = {})
      retry_on_timeout {
	    return agent.volumes
	  }
    end
  end
end
