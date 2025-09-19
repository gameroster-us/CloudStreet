class Azure::Resource::ReloadWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, :retry => false, backtrace: true

  def perform(resource_id)
    resource = Azure::Resource.find_by(id: resource_id)
    return if resource.blank?
    response_status, response = resource.resync

    if response_status.eql?(:success)
      CSLogger.info "#{resource.name} reloaded successfully"
      resource.adapter.account.create_info_alert(:resource_action_alert, { message: "#{resource.name} reloaded successfully", type: 'service_manager_azure'})
    else
      CSLogger.error "#{resource.name} reloading error"
      resource.adapter.account.create_error_alert(:resource_action_alert, { message: response[:error_message], type: 'service_manager_azure'})
    end
    resource.reload
    
    representer_klass = resource.class.get_representer_for(:service_manager)
    node_params = {
      type: "service_manager_azure" ,
      action: 'reload',
      resource_type: resource.type, 
      resource: resource.extend(representer_klass.constantize).to_json(user_options: { current_tenant_currency: ['USD', 1] } ),
      account_id: resource.account_id,
      action_status: response_status
    }
    node_params.merge({error: response}) if [:validation_error, :error].include?(response_status)
    NodeManager.send_data('service_manager/azure', node_params)
  end
end
