class Api::V2::AWS::ServiceGroupsController < Api::V2::SwaggerBaseController
  include Api::V2::Concerns::ParamsValidator
  include Api::V2::Concerns::ParamsUpdater
  include Api::V2::Concerns::Validator::Group

  before_action :validate_tag_key, :is_feature_enabled, :update_service_group_params, :validate_account_group_tags, only: [:create, :update]
  before_action :valid_aws_billing_adapter, only: [:create, :update]
  before_action :valida_normal_adapter_ids, only: [:create, :update]
  before_action :valid_aws_service_group, except: [:index, :create, :create_or_update_groups, :initiate_post_activity_worker]
  before_action :confirm_privileges, only: [:update, :destroy]
  actions_to_skip = [:create_or_update_groups, :initiate_post_activity_worker]
  actions = { index: 'read' }
  authorize_actions_for(ServiceGroup, except: actions_to_skip, actions: actions)

  def index
    ServiceGroupService.search(current_account, current_tenant, params.merge(provider_type: 'AWS')) do |result|
      result.on_success { |service_groups| respond_with_user_and service_groups[0], total_records: service_groups[1], selected_service_groups: service_groups[2], represent_with: V2::ServiceGroupsRepresenter, status: :ok }
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
    Groups::Creator.call(current_account, current_tenant, formatted_group_params.merge(provider_type: 'AWS', type: 'generic'), from_v2_api: V2_API) do |result|
      result.on_success { |service_group| respond_with_user_and service_group, represent_with: V2::ServiceGroupObjectRepresenter }
      result.on_validation_error { |error| render status: 422, json: { validation_error: error } }
      result.on_error   { |message| render json: { message: message }, status: 500 }
    end
  end

  def update
    Groups::Updater.call(current_account, @service_group, formatted_group_params.merge(provider_type: 'AWS', type: 'generic'), current_tenant, @user, from_v2_api: V2_API) do |result|
      result.on_success { |response| render json: { success: 'Success! Service Group Updated.' }, status: 200 }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def destroy
    Groups::Deleter.call(current_account, params[:id], @user, from_v2_api: V2_API) do |result|
      result.on_success { |response| render json: response, status: 200 }
      result.on_error { render body: nil, status: 500 }
    end
  end

  def create_or_update_groups
    if params[:name].present? && params[:name].start_with?("Default_")
      current_group = ServiceGroup.aws_groups.where(account_id: current_account.id).find_by(name: params[:name])
      status, result = if ServiceGroup.aws_groups.where(account_id: current_account.id).find_by(name: params[:name]).present?
                        # update default group
                        Groups::Updater.call(current_account, current_group, formatted_group_params_for_update.merge(provider_type: 'AWS', type: 'generic', custom_data: format_custom_data), current_tenant, @user, from_v2_api: V2_API)
                      else
                        # create default group
                        Groups::Creator.call(current_account, current_tenant, formatted_group_params.merge(provider_type: 'AWS', type: 'generic'), from_v2_api: V2_API)
                      end
      if status
        all_matching_groups = ServiceGroup.aws_groups.where(account_id: current_account.id).where("name like 'Default_%'").search_by_normal_adapters(params[:normal_adapter_ids])
        current_group = (current_group || ServiceGroup.aws_groups.where(account_id: current_account.id).find_by(name: params[:name]))
        overlapped_groups = all_matching_groups.where.not(id: current_group.try(:id))
        overlapped_group_params = formatted_group_params.slice(:normal_adapter_ids, :billing_adapter_id).merge(provider_type: 'AWS')
        Groups::Updater.handle_overlapping_default_groups(overlapped_groups, overlapped_group_params, current_group, current_account, current_tenant, @user, from_v2_api: V2_API) if overlapped_groups.present?
        render(status: 200, json: { message: 'Success! Service Group Updated/Created' })
      else
        render(status: 500, json: { error_msgs: result })
      end
    elsif params[:name].present? && ServiceGroup.where(name: params[:name], account_id: current_account.id).exists?
      service_group = ServiceGroup.find_by(name: params[:name], provider_type: 'AWS')
      Groups::Updater.call(current_account, service_group, formatted_group_params_for_update.merge(provider_type: 'AWS', type: 'generic', custom_data: format_custom_data), current_tenant, @user, from_v2_api: V2_API) do |result|
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
                  :worker_should_initiate,
                  :tag_query_operator,
                  :account_tag,
                  :group_based_on_account_tag,
                  :aws_account_tag_key,
                  normal_adapter_ids: [],
                  tags: %i[tag_key tag_value tag_operator],
                  custom_data: %i[key value])
  end

  # In Script we have requirmet for client to not update name and tag field
  # So we have not added in whitelist params
  def formatted_group_params_for_update
    params.permit(:description,
                  :provider_type,
                  :billing_adapter_id,
                  :type,
                  :worker_should_initiate,
                  normal_adapter_ids: [],
                  custom_data: %i[key value])
  end

   def formatted_group_params_default
    params.permit(:name,
                  :provider_type,
                  :billing_adapter_id,
                  normal_adapter_ids: [],
                  custom_data: %i[key value])
  end

  def formatted_group_normal_adapter_ids_params
    params.permit(:provider_type,
                  :billing_adapter_id,
                  :normal_adapter_ids)
  end

  def post_activity_params
    params.permit(:id)
  end
end
