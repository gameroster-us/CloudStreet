class ProviderWrappers::AWS::Networks::ElasticIP < ProviderWrappers::AWS
  
  def fetch_server(server_id)
    agent.addresses.get(server_id) if server_id
  end

  class << self
    def all(agent, filters = {})
      options = {}
      options.merge!({"network-interface-id" => filters["network-interface-id"]}) if filters["network-interface-id"].present?
      options.merge!({'public-ip' => filters[:provider_ids]}) if filters[:provider_ids].present?
      retry_on_timeout {
        return agent.addresses.all(options)
      }
    end
  end
end
