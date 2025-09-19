module Behaviors
  module TemplateDeployable
    module Azure
      module Network
        module PublicIPAddress
          def form_template_deployer_hash
            {
              "type" => "Microsoft.Network/publicIPAddresses",
              "name" => self.name,
              "apiVersion" => "2017-06-01",
              "location" => self.location,
              "properties" => {
                "ipAddress" => self.ip_address,
                "publicIPAddressVersion" => "IPv4",
                "publicIPAllocationMethod" => self.public_ipallocation_method,
                "idleTimeoutInMinutes" => self.idle_timeout_in_minutes
              },
              "dependsOn" => []
            }
          end
        end
      end
    end
  end
end