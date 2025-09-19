module Behaviors
  module AttachDetach
    module AWS
      module ElasticIP

        ATTACHABLE_SERVICES = ["Services::Compute::Server::AWS", "Services::Network::NetworkInterface::AWS"]

        def detach_server(options)
          self.provider_data["server_id"] = self.server_id = nil
          self.cost_by_hour = self.calculate_hourly_cost
        end

        def mark_as_detached
          self.provider_data["server_id"] = self.server_id = nil
          self.provider_data["network_interface_id"] = nil
          self.is_additional = false
          self.provider_data.delete("association_id")
          self.provider_data.delete("server_state")
          self.vpc_id = nil
          self.interfaces.destroy_all
          self.cost_by_hour = self.calculate_hourly_cost
        end

      end
    end
  end
end
