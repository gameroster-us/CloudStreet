class Azure::Resource::RemoteAction::VmStartStopWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, :retry => false, backtrace: true

  def perform(vm_id, action, currency_rate)
    virtual_machine = Azure::Resource::Compute::VirtualMachine.find_by_id(vm_id)
    return if virtual_machine.blank?
    response_status, response = virtual_machine.send(action)
    if response_status.eql?(:success)
      CSLogger.info "Virtual Machine #{virtual_machine.name} #{action} run successfully"
    else
      CSLogger.info "Virtual Machine #{virtual_machine.name} #{action} failed"
    end
    options = {user_options: {current_tenant_currency: currency_rate[1]}}
    node_params = {type: "service_manager_azure" ,resource_type: virtual_machine.type, resource:  virtual_machine.extend(ServiceManager::Azure::Resource::VirtualMachineRepresenter).to_json(options), account_id: virtual_machine.adapter.account_id}
    NodeManager.send_data('service_manager/azure', node_params)
  end
end
