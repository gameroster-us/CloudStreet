module GCP::Resource::RemoteActions::Compute::VirtualMachine

  def start_resource
    raise NotImplementedError.new("start_resource implementation is pending!")
  end

  def stop_resource
    vm_previous_state = state
    update_attribute(:state, 'stopping')
    res = adapter.gcp_virtual_machine.stop(resource_id: provider_id, zone: gcp_resource_zone.code)
    res.on_success do |response_data|
      self.state = "terminated"
      self.data["vm_status"] = "stopped"
      return :success, self if self.save
    end

    res.on_error do |error_code, error_message, error_data|
      update_attribute(:state, vm_previous_state)
      return :error, { error_code: error_code, error_message: error_message, error_data: error_data }
    end
  rescue StandardError => e
    update_attribute(:state, vm_previous_state)
    return :error, { error_message: e.message }
  end

  def delete_resource
    vm_previous_state = state
    res = adapter.gcp_virtual_machine.delete(resource_id: provider_id, zone: gcp_resource_zone.code)
    res.on_success do |response_data|
      self.state = "deleted"
      self.data["vm_status"] = "stopped"
      return :success, self if self.save
    end

    res.on_error do |error_code, error_message, error_data|
      update_attribute(:state, vm_previous_state)
      return :error, { error_code: error_code, error_message: error_message, error_data: error_data }
    end
  rescue StandardError => e
    update_attribute(:state, vm_previous_state)
    return :error, { error_message: e.message }
  end

end
