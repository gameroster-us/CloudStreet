class TenantsController < ApplicationController
  authorize_actions_for Tenant, :except => [:index, :available_tenants, :set_current_tenant, :tenant_resource_groups, :get_currency, :tenants_list, :assigned_users, :current_tenant_users]
  authority_actions :assign_tenants => 'manage', :update_tenant_permission => 'manage', :remove_tenants => 'manage'

  def index
    authorize_action_with_condition(:index, Tenant)

    Tenant::Searcher.find_own_tenants(current_organisation,user) do |result|
      result.on_success { |tenants| respond_with tenants, status: 200 }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def show
    Tenant::Searcher.find(params[:id]) do |result|
      result.on_success { |tenant| respond_with tenant, status: 200 }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def create
    Tenant::Creater.create(current_organisation, user, params, tenant_params) do |result|
      result.on_success          { |tenant| respond_with tenant, status: 200 }
      result.on_validation_error { |tenant| render status: 422, json: cloudstreet_error(:validation_error, tenant.errors.messages) }
    end
  end

  def update
    Tenant::Updater.update(current_organisation, user, params[:id], tenant_params, params, set_user_activity_details) do |result|
      result.on_success { |tenant| respond_with tenant, status: 200 }
      result.on_validation_error { |message| render json: { validation_error: message}, status: 422 }
      result.on_error   { |message| render json: { error: message}, status: 500 }
    end
  end
  
  def destroy
    Tenant::Deleter.delete(params[:id]) do |result|
      result.on_success { render json: {}, status: 200 }
      result.on_validation_error { |message| render json: { validation_error: message}, status: 422 }
      result.on_error { |message| render json: { validation_error: message }, status: 500 }
    end
  end

  def tenants_list
    authorize_action_with_condition(:tenants_list, Tenant)

    Tenant::Searcher.fetch_tenants_list(current_organisation, user, params) do |result|
      result.on_success { |tenants| respond_with tenants, represent_with: TenantsListRepresenter, status: 200 }
      result.on_error   { render body: nil, status: 500 }
    end
  end
    
  def available_tenants
    authorize_action_with_condition(:available_tenants, Tenant)

    Tenant::Searcher.find_available_tenants(current_organisation, user) do |result|
      result.on_success { |tenants| render json: {"current_tenant" => current_tenant.try(:id), "tenants" => tenants} }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def get_currency
    Tenant::Searcher.fetch_tenant_currency(current_tenant) do |result|
      result.on_success { |tenants| render json: {"tenants" => tenants} }
      result.on_error   { render body: nil, status: 500 }
    end
  end
      
  def set_current_tenant
    authorize_action_with_condition(:set_current_tenant, Tenant)

    Tenant::Updater.set_current_tenant(current_organisation, user, params) do |result|
      result.on_success { |response| render json: response, status: 200 }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def assign_tenants
    UserUpdater.assign_tenants(current_organisation,assign_tenants_params, @organisation_host) do |result|
      result.on_success { render json: {}, status: 200 }
      result.on_error   { render json: {}, status: 500 }
    end
  end

  def update_tenant_permission
    UserUpdater.update_tenant_permission(current_organisation,assign_tenants_params, @organisation_host) do |result|
      result.on_success { render json: {}, status: 200 }
      result.on_error   { render json: {}, status: 500 }
    end
  end

  def remove_tenants
    UserUpdater.remove_tenants(current_organisation,remove_tenants_params) do |result|
      result.on_success { render json: {}, status: 200 }
      result.on_validation_error { |errors| render json: errors, status: 422 }
      result.on_error   { render json: {}, status: 500 }
    end
  end

  def tenant_resource_groups
    Tenant::ResourceGroup.list(resource_group_params, current_tenant, current_account) do |result|
      result.on_success { |response| render json: {resource_groups: response}, status: 200 }
      result.on_error   { |errors| render status: 500, json: { errors: errors } }
    end
  end

  def assigned_users
    Tenant::Searcher.fetch_assigned_users(current_organisation, user, params) do |result|
      result.on_success { |response| render json: { result: response[0], total_records: response[1] },  status: 200 }
      result.on_error   { |e| render json: { error_message: e }, status: 500 }
    end
  end
  
  def current_tenant_users
    Tenant::Searcher.tenant_users(current_tenant, params) do |result|
      result.on_success { |tenant_users| render json: tenant_users }
      result.on_error   { |error| render json: { error:  error }, status: 500 }
    end
  end

  private

  def tenant_params
    params.permit(:name, :state, :organisation_id, :exclude_edp, :enable_currency_conversion, :default_currency, :report_profile_id,
                  selectedAdapter: [], sso_keywords: [], selected_adapter_group: [], selectedResourceGroups: [],
                  tags: [:tag_key, :tag_value, :tag_sign], all_selected_flags: {})
  end

  def assign_tenants_params
    params.permit(:tenant_id, user_ids: [:user_id, :role_ids => []])
  end

  def remove_tenants_params
    params.permit(:tenant_id, :user_id)
  end

  def resource_group_params
    params.permit(:adapter_id, :name, :tenantId, :page, :per_page, :keyword_filter_by_name, selectedAdapter: [], selected_adapter_group: [])
  end

  def set_user_activity_details
    {
      browser: request.env['HTTP_USER_AGENT'],
      controller: controller_name,
      action: 'tenant_update',
      ip_address: (request.env['HTTP_X_FORWARDED_FOR'] || request.env['REMOTE_ADDR']),
      user_id: user.id,
      account_id: current_account.id
    }
  end

end
