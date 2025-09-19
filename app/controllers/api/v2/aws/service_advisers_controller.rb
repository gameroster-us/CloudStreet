class Api::V2::AWS::ServiceAdvisersController < Api::V2::SwaggerBaseController

  include ApplicationHelper
  include Api::V2::Concerns::ParamsValidator
  include Api::V2::Concerns::Validator::ServiceAdviser
  include Api::V2::Concerns::Extras::ServiceAdviser
  
  BOOLEAN_ARRAY = { "false" => false, "true" => true}.freeze

  authorize_actions_for ServiceAdviserAuthorizer, except:
  [
    :get_right_sized_instances
  ],
  actions: {
    list_service_type_with_detail: 'read',
    show_ignored_services: 'read',
    list_service_type_with_count: 'read',
    get_key_values_array: 'read'
  }

  before_action :valid_aws_adapter_for_service_adviser, :valid_service_type, :valid_service_group, :fetch_adapter_ids_by_group_id, :reassign_adapter_ids, :except => [:show_ignored_services, :get_right_sized_instances]

  def get_key_values_array
    authorize_action_with_condition(:get_key_values_array, ServiceAdviserAuthorizer)
    adapter_ids = @adapter_ids.blank? ? current_tenant.adapters.aws_adapter.normal_adapters.try(:ids) : @adapter_ids
    filters = { adapter_id: adapter_ids, lifecycle: params[:lifecycle] }
    filters.merge!({region_id: params[:region_id]}) if params[:region_id]
    result = ServiceAdviser::AWS.get_key_values_array(filters, current_tenant, current_account) do |result|
      result.on_success { |response|  render json: {response: response} }
      result.on_error { |e| render json: {error_message: e.message}, status: 422 }
    end
  end

  def list_service_type_with_count
    current_tenant_currency_all_provider_hsh = current_tenant_currency_all_provider
    current_tenant_currency_rates = current_tenant_currency_all_provider_hsh[:AWS]
    ServiceAdviser::AWS.list_service_type_with_count(common_filters, current_account, current_tenant, user, current_tenant_currency_rates) do |result|
      result.on_success { |response|  render json: {response: response} }
      result.on_error do |e|
        CSLogger.error("#{e.class} : #{e.message}")
        CSLogger.error(e.backtrace)
        render json: {error_message: e.message}, status: 422
      end
    end
  end

  def list_service_type_with_detail
    current_tenant_currency_all_provider_hsh = current_tenant_currency_all_provider
    current_tenant_currency_rates = current_tenant_currency_all_provider_hsh[:AWS]
    paginate = { page: params[:page].to_i, per_page: params[:per_page].to_i }
    sort_by = 'provider_created_at ASC'
    ServiceAdviser::AWS.list_service_type_with_detail(common_filters, paginate, sort_by, current_account, current_tenant, user) do |result|
      result.on_success { |response| respond_with_user_and response, user_options: { current_user: user, current_account: current_account, current_tenant: current_tenant, currency_code: current_tenant_currency_rates[0], currency_rate: current_tenant_currency_rates[1] }, represent_with: ServiceAdviser::AWS::ListServiceTypeWithDetailRepresenter }
      result.on_error do |e|
        CSLogger.error("#{e.class} : #{e.message}")
        CSLogger.error(e.backtrace)
        render json: {error_message: e.message}, status: 422
      end
    end
  end

  def get_right_sized_instances
    current_tenant_id = current_tenant.id
    authorize_action_with_condition(:get_right_sized_instances, ServiceAdviserAuthorizer)
    Rightsizings::RightSizingService.get_right_sized_instances(params, current_account, current_tenant) do |result|
      result.on_success { |response| respond_with response[0], user_options: { current_user: @user, current_account: current_account, current_tenant: current_tenant}, total_records: response[1], represent_with: ServiceAdviser::AWS::EC2RightsizingInstancesSummaryRepresenter, status: 200 }
      result.on_error { |e| render json: {error_message: e.message}, status: 422 }
    end
  end

  def show_ignored_services
    result = ServiceAdviser::AWS.show_ignored_services(current_account, current_tenant, params) do |result|
      result.on_success do |response|
        respond_to do |format|
          format.any { render json: response.to_json, status: :ok }
        end
      end
      result.on_error { |e| render json: { error_message: e.message }, status: 422 }
    end
  end

  private

  def common_filters
    tags = JSON.parse(params["tags"]) rescue []
    {
      adapter_id: @adapter_ids, region_id: params[:region_id],
      service_type: V2::Swagger::Constants::AWS_SERVICE_TYPE[params[:service_type]], environment_id: params[:environment_id],
      public_snapshot: params[:public_snapshot], tags: tags, lifecycle: params[:lifecycle],
      cpu_utilization: params[:cpu_utilization], memory_utilization: params[:memory_utilization], vcenter_id: params[:vcenter_id],
      tag_operator: params[:tag_operator].blank? ? "OR" : params[:tag_operator]
    }
  end

end
