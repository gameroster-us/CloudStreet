class Api::V2::GCP::ServiceManager::DisksController < Api::V2::ServiceManagerBaseController
  authorize_actions_for ServiceManagerAuthorizer, actions:  { index: 'read'}
  before_action :valid_gcp_adapter, :valid_gcp_service_group

  def index
    ServiceManager::GCP::Resource::Fetcher.fetch(current_account, current_tenant, service_manager_params) do |result|
      result.on_success { |response| respond_with response[:resources], user_options: { current_tenant_currency: current_tenant_currency(CommonConstants::PROVIDER) }, represent_with: ::V2::GCP::ServiceManager::ResourcesRepresenter, total_records: response[:total_records], resource_type: response[:resource_type], status: 200 }
      result.on_error   { |errors| render status: 500, json: { errors: errors } }
    end
  end

  private

  def service_manager_params
    params[:type] = "GCP::Resource::Compute::Disk"
    params.permit(:type, :tags, :page_number, :page_size, :region_id, :name, :tag_operator, :adapter_group_id, adapter_id: [])
  end

end
