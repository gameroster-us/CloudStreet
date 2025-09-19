module Behaviors
  module Costable
    module Amazon
      module ElasticIP
        def compute_hourly_cost(template_costs)
          # attached_eip_count = 0
          # if service.is_attached?
          #   env = service.environment
          #   if service.provider_data['server_id']
          #     attached_server = env.services.where(:type => "Services::Compute::Server::AWS", :provider_id => service.provider_data['server_id']).first
          #     attached_eip_count = env.services.where("provider_data ->> 'server_id' =  \'#{attached_server.provider_id}\' AND type = 'Services::Network::ElasticIP::AWS'").count 
          #   end
          #   if attached_eip_count == 1
          #     service_cost = 0
          #   else
          #     service_cost = template_costs["elastic_ips"]["perAdditionalEIPPerHour"] rescue 0
          #   end
          # else
          #   service_cost = template_costs["elastic_ips"]["perNonAttachedPerHour"] rescue 0
          # end
          # service_cost.nil? ? 0 : service_cost
          if self.server_id.nil?
            template_costs["elastic_ips"]["perNonAttachedPerHour"]
          else
            if self.server_state.eql?("running")
              if self.is_additional
                template_costs["elastic_ips"]["perAdditionalEIPPerHour"]
              else
                0.0
              end
            else
              template_costs["elastic_ips"]["perNonAttachedPerHour"]
            end
          end
        rescue Exception => e
          # CSLogger.error("error in cost cacl #{e.class} #{e.message} #{e.backtrace}")
          0.0
        end
      end
    end
  end
end