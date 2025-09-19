class Api::V2::Azure::ServiceGroupsController < Api::V2::SwaggerBaseController

  include Api::V2::Concerns::Validator::Group
  include Api::V2::Concerns::ParamsValidator

  before_action :validate_tag_key, only: [:index, :create, :update]
  before_action :valid_azure_billing_adapter, :valid_customer_id, :valida_normal_adapter_ids, :validate_customer_data, only: [:create, :update]
  before_action :valid_azure_service_group, except: [:index, :create, :custom_data, :create_or_update_groups, :initiate_post_activity_worker]
  before_action :confirm_privileges, only: [:update, :destroy]
  actions_to_skip = [:create_or_update_groups, :initiate_post_activity_worker]

  authorize_actions_for ServiceGroup, actions: { index: 'read', custom_data: 'read' }, except: actions_to_skip

  def index
    ServiceGroupService.search(current_account, current_tenant, params.merge(provider_type: 'Azure')) do |result|
      result.on_success { |service_groups| respond_with_user_and service_groups[0], total_records: service_groups[1], selected_service_groups: service_groups[2], is_csp_adapter_present: service_groups[3], represent_with: V2::ServiceGroupsRepresenter, status: :ok }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def show
    ServiceGroupService.find(@service_group, params.merge(only_show: true), current_tenant) do |result|
      result.on_success { |service_group| respond_with_user_and service_group, represent_with: V2::ServiceGroupObjectRepresenter }
      result.on_error   { render body: nil, status: 500 }
      result.on_unauthorized   { render json: { message: "Access denied" }, status: 402 }
    end
  end

  def create
    Groups::Creator.call(current_account, current_tenant, formatted_group_params.merge(provider_type: 'Azure', type: 'generic'), from_v2_api: V2_API) do |result|
      result.on_success { |service_group| respond_with_user_and service_group, represent_with: V2::ServiceGroupObjectRepresenter }
      result.on_validation_error { |error| render status: 422, json: { validation_error: error } }
      result.on_error   { |message| render json: { message: message }, status: 500 }
    end
  end

  def update
    Groups::Updater.call(current_account, @service_group, formatted_group_params.merge(provider_type: 'Azure', type: 'generic'), current_tenant, @user, from_v2_api: V2_API) do |result|
      result.on_success { |response| render json: { success: 'Success! Service Group Updated.' }, status: 200 }
      result.on_error   { |errors| render json: { errors: errors}, status: 500 }
    end
  end

  def destroy
    Groups::Deleter.call(current_account, params[:id], @user, from_v2_api: V2_API) do |result|
      result.on_success { |response| render json: response, status: 200 }
      result.on_error { render body: nil, status: 500 }
    end
  end

  def custom_data
    Groups::GroupSearcher.groups_custom_data(current_account, current_tenant, params.merge(provider_type: 'Azure')) do |result|
      result.on_success { |response| render json: response }
      result.on_error   { |e| render json: { error_message: e.message }, status: 500 }
    end
  end

  def create_or_update_groups
    if params[:name].present? && params[:name].start_with?("Default_")
      current_group = ServiceGroup.azure_groups.where(account_id: current_account.id).find_by(name: params[:name])
      status, result = if current_group
                        # update default group
                        Groups::Updater.call(current_account, current_group, formatted_group_params_for_update.merge(provider_type: 'Azure', type: 'generic', custom_data: format_custom_data), current_tenant, @user, from_v2_api: V2_API)
                      else
                        # create default group
                        Groups::Creator.call(current_account, current_tenant, formatted_group_params.merge(provider_type: 'Azure', type: 'generic'), from_v2_api: V2_API)
                      end
      if status
        all_matching_groups = ServiceGroup.azure_groups.where(account_id: current_account.id).where("name like 'Default_%'").search_by_normal_adapters(params[:normal_adapter_ids])
        current_group = (current_group || ServiceGroup.azure_groups.where(account_id: current_account.id).find_by(name: params[:name]))
        overlapped_groups = all_matching_groups.where.not(id: current_group.try(:id))
        overlapped_group_params = formatted_group_params.slice(:normal_adapter_ids, :billing_adapter_id).merge(provider_type: 'Azure')
        Groups::Updater.handle_overlapping_default_groups(overlapped_groups, overlapped_group_params, current_group, current_account, current_tenant, @user, from_v2_api: V2_API) if overlapped_groups.present?
        render(status: 200, json: { message: 'Success! Service Group Updated/Created' })
      else
        render(status: 500, json: { error_msgs: result })
      end
    elsif params[:name].present? && ServiceGroup.azure_groups.where(name: params[:name], account_id: current_account.id).exists?
      service_group = ServiceGroup.azure_groups.find_by(name: params[:name], account_id: current_account.id)
      Groups::Updater.call(current_account, service_group, formatted_group_params_for_update.merge(provider_type: 'Azure', type: 'generic', custom_data: format_custom_data), current_tenant, @user, from_v2_api: V2_API) do |result|
        result.on_success { |response| render json: { success: 'Success! Service Group Updated.' }, status: 200 }
        result.on_error { |message| render status: 500, json: { error_msgs: message } }
      end
    else
      create
    end
  end

  def initiate_post_activity_worker
    ServiceGroupService.initiate_post_activity_worker_for_an_account(post_activity_params) do |result|
      result.on_success { |response| render json: { success: 'Success! Account Post Activity Initiated.' }, status: 200 }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  private

  def formatted_group_params
    service_group_params.merge(custom_data: format_custom_data)
  end

  def format_custom_data
    return [] if service_group_params[:custom_data].blank?
    
    service_group_params[:custom_data].each_with_object({}) do |custom_data, memo|
      memo.merge!(custom_data[:key] => custom_data[:value])
    end
  end

  def service_group_params
    params.permit(:name,
                  :description,
                  :provider_type,
                  :billing_adapter_id,
                  :type,
                  :customer_id,
                  :customer_name,
                  normal_adapter_ids: [],
                  tags: %i[tag_key tag_value],
                  custom_data: %i[key value])
  end

  # In AWS Script we have requirment for client to not update name and tag field
  # So we have not added in whitelist params in Azure too
  def formatted_group_params_for_update
    params.permit(:description,
                  :provider_type,
                  :billing_adapter_id,
                  :type,
                  :worker_should_initiate,
                  normal_adapter_ids: [],
                  custom_data: %i[key value])
  end

  def post_activity_params
    params.permit(:id)
  end
end
