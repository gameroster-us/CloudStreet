class ProviderWrappers::AWS::Networks::NetworkInterface < ProviderWrappers::AWS

  def fetch_remote_interface(provider_id)    
    agent.network_interfaces.get(provider_id)   
  end


  def update_private_ips(provider_id)
    user_private_ips = service.private_ips.collect {|p_ip_hash| p_ip_hash['primary'] == "false" && p_ip_hash['privateIpAddress']}.select(&:presence)
    CSLogger.info "private_ips:  #{user_private_ips}"
    CSLogger.info "service: #{service.inspect}"
    if user_private_ips.blank?
      auto_ip_count = 0
      service.private_ips.each do |ip_hash|
        next(ip_hash) unless ip_hash['primary'] == "false" && ip_hash['privateIpAddress'].blank?
        auto_ip_count +=1
      end
      # service.private_ips.inject(0) {|count,hash| count+=1 if (hash['primary'] == "false" && hash['privateIpAddress'].present?) }
      CSLogger.info "auto_ip_count: #{auto_ip_count}"
      agent.assign_private_ip_addresses(provider_id, 'SecondaryPrivateIpAddressCount'=> auto_ip_count) if auto_ip_count && auto_ip_count !=0
    else
      agent.assign_private_ip_addresses(provider_id, 'PrivateIpAddresses'=> user_private_ips)
    end
  end    

  class << self
    def all(agent, filters = {})
      options = {}
      options.merge!({'network_interface_id' => filters[:provider_ids]}) if filters[:provider_ids] .present?
      retry_on_timeout {
        return agent.network_interfaces(options)
      }
    end

    def get(agent, interface_id)
      agent.network_interfaces.get(interface_id)
    end
  end
end
