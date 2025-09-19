module Parsers
  module Azure
    module Compute
      class AvailabilitySet < Parsers::Azure::Service
        def initialize(remote_availability_set)
          super(remote_availability_set)
        end

        def parse_to_azure_service_params
          remote_availability_set_data = @remote_service_object["properties"]
          super.merge!(
            {
              "update_domain_count" => Parsers::Azure::Service.dig(remote_availability_set_data, @service_metadata, 1, "platform_update_domain_count"),
              "fault_domain_count" => Parsers::Azure::Service.dig(remote_availability_set_data, @service_metadata, 1, "platform_fault_domain_count"),
              "virtual_machines" => parse_virtual_machine_names
            }
          )
        end

        def parse_virtual_machine_names
          vm_ids = []
          vms_arr = Parsers::Azure::Service.dig(@remote_service_object, @service_metadata, [], "properties", "virtual_machines"),
          vm_ids = vms_arr.map{|vm| vm["id"]} if vms_arr.present?
          vm_ids
        end
      end
    end
  end
end