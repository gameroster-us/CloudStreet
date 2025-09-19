class Api::V2::AWS::ServiceManager::LoadBalancersController < Api::V2::ServiceManagerBaseController
  authorize_actions_for ServiceManagerAuthorizer, actions:  { index: 'read'}
  before_action :valid_aws_adapter, :valid_aws_service_group

  def index
    ServiceManagerService.list_services_details(current_account, current_tenant, service_manager_params) do |result|
      result.on_success { |service_manager| respond_with_user_and service_manager, user_options: { current_tenant_currency: current_tenant_currency('AWS') }, represent_with: ServiceManagersRepresenter }
      result.on_error   { |errors| render status: 500, json: { errors: errors } }
      result.on_validation_error { |error_msgs| render status: 400, json: { validation_error: error_msgs } }
    end
  end

  private

  def service_manager_params
    params[:type] = "loadbalancer"
    params.permit(:type, :account_id ,:page, :per_page, :region_id, :vpc_id, :name, :state, :search_text, :encrypted,:lifecycle, :tags, :instance_type, :subnet_id, :adapter_group_id, adapter_id: [])
  end

end
