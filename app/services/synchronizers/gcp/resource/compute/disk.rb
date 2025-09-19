# GCP DISK fetching logic
module Synchronizers::GCP::Resource::Compute::Disk
  def fetch_provider_services(adapter, gcp_zone_code)
    response = adapter.gcp_disk.list({zone: gcp_zone_code})
    response = response.with_formatter(GCP::RemoteResourceObject::Compute::Disk)
    response.on_success do |data|
    #   provider_data.each do |remote_service|
    #     res = adapter.azure_virtual_machines.instance_view(resource_group_name, remote_service.provider_id)
    #     res.on_success do |data|
    #       vm_status = data.statuses.select { |s| s.code.include?("PowerState") }.first
    #       remote_service.vm_status = self.get_vm_cloudstreet_status(vm_status.code.split("/").last) if vm_status.present?
    #       # remote_service.provider_data['is_aks_node'] = check_for_aks_image_reference(remote_service.storage_profile['image_reference'])
    #     end
    #   end
      return data
    end

    response.on_error do |error_code, error_message, data|
      CSLogger.error "ERROR Synchronizers::GCP::Resource::Compute::Disk | Adapter id: #{adapter.id} | gcp_zone_code: #{gcp_zone_code} | Error : #{error_code} : #{error_message}"
      return []
    end
  end
end
