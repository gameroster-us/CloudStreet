# GCP Virtual Machine fetching logic
module Synchronizers::GCP::Resource::Compute::VirtualMachine
  def fetch_provider_services(adapter, gcp_zone_code)
    response = adapter.gcp_virtual_machine.list({ zone: gcp_zone_code })
    response = response.with_formatter(GCP::RemoteResourceObject::Compute::VirtualMachine)
    response.on_success do |provider_data|
      provider_data.each do |remote_service|
        api_machine_type = remote_service['machine_type']&.split('machineTypes/')&.last
        break if api_machine_type.nil? || api_machine_type.empty?

        res = adapter.gcp_machine_type.get({zone: gcp_zone_code, machine_type: api_machine_type})
        res.on_success do |data|
          remote_service.vm_cpu = data['guestCpus']
          remote_service.vm_ram = data['memoryMb']
        end
      end
      return provider_data
    end

    response.on_error do |error_code, error_message, data|
      CSLogger.error "ERROR Synchronizers::GCP::Resource::Compute::VirtualMachine | adapter_id : #{adapter.id} | gcp_zone_code :#{gcp_zone_code} | Error - #{error_code} : #{error_message}"
      return []
    end
  end

  # def fetch_machine_type(remote_service)
  #   remote_service['machine_type']&.split('machineTypes/')&.last
  # end
end