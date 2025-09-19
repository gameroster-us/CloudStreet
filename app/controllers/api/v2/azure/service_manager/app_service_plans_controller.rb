class Api::V2::Azure::ServiceManager::AppServicePlansController < Api::V2::ServiceManagerBaseController
  authorize_actions_for ServiceManagerAuthorizer, actions:  { index: 'read'}
  before_action :valid_azure_adapter, :valid_azure_service_group

  def index
    ServiceManager::Azure::Resource::Fetcher.fetch(service_manager_params, current_account, current_tenant) do |result|
      result.on_success { |response| respond_with response[:resources], user_options: { current_tenant_currency: current_tenant_currency(CommonConstants::PROVIDER) }, represent_with: ::V2::Azure::ServiceManager::ResourcesRepresenter, total_records: response[:total_records], resource_type: response[:resource_type], status: 200 }
      result.on_error   { |errors| render status: 500, json: { errors: errors } }
    end
  end

  private

  def service_manager_params
    params[:type] = "Azure::Resource::Web::AppServicePlan"
    params.permit(:type, :tags, :azure_resource_group_id, :region_id, :name, :page_number, :page_size, :state, :adapter_group_id, adapter_id: [])
  end

end
