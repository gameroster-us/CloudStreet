# frozen_string_literal: true

class Api::V2::Azure::AdaptersController < Api::V2::SwaggerBaseController
  include Api::V2::Concerns::ParamsValidator

  before_action :check_validation, :except => [:index, :remove, :delete_all, :verify_credential, :customer_ids, :azure_office365_services]
  before_action :credential_verification, :except => [:index, :remove, :delete_all, :verify_credential, :customer_ids, :azure_office365_services]
  before_action :valid_export_confi, :valid_margin_discount, :only => [:create_billing, :update_billing]
  before_action :get_tenant_adapter, :only => [:update_normal, :update_billing, :remove]
  before_action :billing_adapter_presence, only: :customer_ids


  authorize_actions_for Adapter,
  except: [:index],
  actions: {
    create_normal: 'create',
    update_normal: 'update',
    remove: 'delete',
    create_billing: 'create',
    verify_credential: 'read',
    update_billing: 'update',
    delete_all: 'delete',
    customer_ids: 'read',
    azure_office365_services: 'read'
  }

  def index
    authorize_action_with_condition(:index, Adapter)
    params[:provider_type] = 'Adapters::Azure'
    params[:show_all] =  true
    V2::Swagger::AdapterService.search(current_tenant, params) do |result|
      result.on_success { |adapters| respond_with_user_and adapters, with_buckets: false, represent_with: V2::Azure::AdapterListRepresenter }
      result.not_found  { |message| render json: { message: message }, status: 404 }
      result.on_validation_error { |error| render status: 422, json: { validation_error: error } }
      result.on_error   { |errors| render body: nil, json: { errors: errors } }
    end
  end

  def create_normal
    authorize_action_for Adapter, { account_id: current_account.id }
    params[:adapter_purpose] = "normal"
    AdapterCreator.create(current_organisation, current_tenant, user.id, adapter_params(get_type(params))) do |result|
      result.on_success { |adapter| respond_with_user_and adapter, with_buckets: true, represent_with: ::V2::Azure::AdapterListObjectRepresenter, location: adapters_url }
      result.on_failed_to_activate { |error| render status: 400, json: cloudstreet_error(:failed_to_activate, [error]) }
      result.on_auth_failure { |error| render status: 400, json: cloudstreet_error(:auth_failure, [error]) }
      result.on_validation_error { |adapter| render status: 422, json: { validation_error: adapter.errors.messages } }
    end
  end

  def create_billing
    authorize_action_for Adapter, { account_id: current_account.id }
    params[:adapter_purpose] = "billing"
    AdapterCreator.create(current_organisation, current_tenant, user.id, adapter_params(get_type(params))) do |result|
      result.on_success { |adapter| respond_with_user_and adapter, with_buckets: true, represent_with: ::V2::Azure::AdapterListObjectRepresenter, location: adapters_url }
      result.on_failed_to_activate { |error| render status: 400, json: cloudstreet_error(:failed_to_activate, [error]) }
      result.on_auth_failure { |error| render status: 400, json: cloudstreet_error(:auth_failure, [error]) }
      result.on_validation_error { |adapter| render status: 422, json: {validation_error: adapter.errors.messages} }
    end
  end

  def update_normal
    AdapterUpdater.update(user.id, current_tenant, @adapter, adapter_params(get_type(params))) do |result|
      result.on_success { |response| render json: { success: 'Success! Adapter Updated.' }, status: 200 }
      result.on_failed_to_activate { |error| render status: 400, json: cloudstreet_error(:failed_to_activate, [error]) }
      result.on_auth_failure { |error| render status: 400, json: cloudstreet_error(:auth_failure, [error]) }
      result.on_invalid_state { |error| render status: 400, json: cloudstreet_error(:invalid_state, [error]) }
      result.on_error { |adapter| respond_with_user_and adapter, status: 422 }
      result.on_validation_error { |adapter| render status: 422, json: { validation_error: adapter.errors.messages } }
    end
  end

  def update_billing
    AdapterUpdater.update(user.id, current_tenant, @adapter, adapter_params(get_type(params))) do |result|
      result.on_success { |response| render json: { success: 'Success! Adapter Updated.' }, status: 200 }
      result.on_failed_to_activate { |error| render status: 400, json: cloudstreet_error(:failed_to_activate, [error]) }
      result.on_auth_failure { |error| render status: 400, json: cloudstreet_error(:auth_failure, [error]) }
      result.on_invalid_state { |error| render status: 400, json: cloudstreet_error(:invalid_state, [error]) }
      result.on_error { |adapter| respond_with_user_and adapter, status: 422 }
      result.on_validation_error { |adapter| render status: 422, json: { validation_error: adapter.errors.messages } }
    end
  end

  def remove
    AdapterDeleter.delete(current_account, @adapter, user) do |result|
      result.on_success { |response| render json: { success: 'Success! Adapter Deleted' }, status: 200 }
      result.on_validation_error { |adapter| respond_with_user_and adapter, status: 422 }
      result.on_error { |message| render status: 500, json: { validation_error: message } }
    end
  end

  # POST /azure/verify_credential
  def verify_credential
    return render json: { message: "Please provide valid adapter purpose." }, status: 422 unless ['normal', 'billing'].include?(params[:adapter_purpose])

    params[:type] = 'Adapters::Azure'
    Adapters::CredentialVerifier.call(credential_verifier_params) do |result|
      result.on_success { |response| render json: response }
      result.on_error   { |response| render json: response, status: 422 }
    end
  end

  # DELETE /azure/adapters/delete_all
  def delete_all
    V2::Swagger::AdapterService.destroy_all(current_account, 'Adapters::Azure') do |result|
      result.on_success { |response| render json: { success: 'All Azure Adapters Deleted Successfully.' }, status: 200 }
      result.not_found  { |message| render json: { message: message }, status: 404 }
      result.on_validation_error { |adapter| render status: 422, json: { validation_error: adapter.errors.messages } }
      result.on_error { |adapter| render body: nil, status: 500, json: { validation_error: adapter } }
    end
  end

  def customer_ids
    AdapterSearcher.get_customer_ids(current_account, current_tenant, {billing_adapter_id: params[:id], per_page: params[:per_page], next_token: params[:next_token], exec_id: params[:exec_id], 'name'=> params[:name]}) do |result|
      result.on_success { |response| render json: response }
      result.on_error { |e| render json: { error_message: e }, status: 500 }
    end
  end

  def azure_office365_services
    AdapterSearcher.get_azure_office365_services do |result|
      result.on_success { |response| render json: response }
      result.on_error { |e| render json: { error_message: e }, status: 500 }
    end
  end

  private

  def credential_verification
    params[:type] = 'Adapters::Azure'
    verrifier_response = Adapters::CredentialVerifier.call(credential_verifier_params)
    validate_subscription_params(verrifier_response[:data]) if params[:subscription_id].present? && params[:subscription].present? && verrifier_response
    Adapters::CredentialVerifier.call(credential_verifier_params) do |result|
      result.on_error   { |response| render json: response, status: 422 }
    end
  end

  def valid_export_confi
    return true if params[:azure_account_type].eql?('csp')

    if params[:export_configuration].blank? || params[:export_configuration][:configuration].blank?
      return render json: { message: "Please provide valid export configuration details." }, status: 422
    end

    unless AzureExportConfiguration.scope_types.keys.include?(params[:export_configuration][:scope])
      return render json: { message: "Export configuration scope must be Billing Account, Management Group or Subscription" }, status: 422
    end

    invalid_export_configs = params[:export_configuration][:is_csd_export] ? get_export_configurations : validate_direct_api_scope_ids
    if invalid_export_configs.count.positive?
      return render json: { message: "Please provide valid export configuration details. Invalid exports are: #{ invalid_export_configs.map { |item| "'#{item}'" }.to_sentence }" }, status: 422
    end
  end

  def get_export_configurations
    params[:export_configuration][:configuration].each_with_object([]) do |configuration, invalid_exports|
      unless valid_scope_and_scope_id(configuration)
        invalid_exports.push(configuration[:name])
        next
      end
      result = Adapters::Creators::Azure.get_azure_export_details(params, configuration)
      invalid_exports.push(configuration[:name]) unless result
    end
  end

  def valid_scope_and_scope_id(configuration)
    return false unless params[:export_configuration][:scope].eql?(configuration[:scope])

    return configuration[:scope_id].include?('subscriptions') if configuration[:scope].eql?('Subscription')

    return configuration[:scope_id].include?('managementGroups') if configuration[:scope].eql?('Management Group')

    return configuration[:scope_id].include?('billingAccounts') if configuration[:scope].eql?('Billing Account')
  end

  def validate_direct_api_scope_ids
    scope_items = Adapters::Creators::Azure.get_scope_item_list(params)
    params[:export_configuration][:configuration].each_with_object([]) do |configuration, invalid_scope_ids|
      invalid_scope_ids.push(configuration[:scope_id]) unless scope_items.any? { |scope_item| scope_item['id'] == configuration[:scope_id] }
    end
  end

  def validate_subscription_params(res)
    res = res.map(){|v| JSON.parse(v.to_json) }
    subscription_params = JSON.parse(params[:subscription].to_json)
    result = res.any? { |subscription| subscription.value?(subscription_params['subscription_id']) && subscription.value?(subscription_params['display_name']) }
    return render json: { message: "Please provide valid subscription details." }, status: 422 unless result
  end

  def adapter_params(klass)
    permits = filter_payload_params(action_name)
    params.permit(permits).to_h
  end

  def get_type(params)
    fail "no tizzype yo" unless params[:type]

    klass = ActionController::Base.helpers.sanitize(params[:type])
    klass = klass.safe_constantize rescue ''
  end

  def filter_payload_params action
    case action
    when 'create_billing', 'update_billing'
      billing_adapter_params
    else
      normal_adapter_params
    end
  end

  def billing_adapter_params
    permit_params = [:type, :name, :client_id, :secret_key, :tenant_id, :adapter_purpose, :azure_account_type, :azure_cloud, :account_setup, :pec_calculation, :subscription_id, :enable_invoice_date, :invoice_date, :include_office_cost, :multi_tenant_setup, multiple_tenant_details: [:adapter_name_prefix, :client_id, :secret_key, :tenant_id], export_configuration: {}, subscription: {}, azure_office_365_services: []]
    permit_params << :margin_discount_calculation if current_organisation.parent_organisation? && params[:azure_account_type].eql?('csp')
    permit_params
  end

  def normal_adapter_params
    [:type, :name, :client_id, :secret_key, :tenant_id, :adapter_purpose, :azure_account_type, :azure_cloud, :currency, :ea_account_setup, :subscription_id, subscription: {}]
  end

  def credential_verifier_params
    params.permit(:type, :adapter_id, :client_id, :adapter_purpose, :secret_key, :tenant_id, :enrollment_number, :access_key, :azure_account_type, :azure_cloud)
  end

  def get_tenant_adapter
    @adapter = current_tenant.adapters.azure_adapter.find(params[:id])
  rescue ActiveRecord::RecordNotFound => e
    render json: { message: "Couldn't find Adapter with id=#{params[:id]}" }, status: 404
  end

  def billing_adapter_presence
    current_tenant.adapters.azure_adapter.billing_adapters.find(params[:id])
  rescue ActiveRecord::RecordNotFound 
    render json: { message: "Billing Adapter is not available !!}" }, status: 404
  end

  def check_validation
    return render json: { message: "Please enter an adapter name that is from 1 to 50 characters long." }, status: 422 unless params[:name].present? && params[:name].to_s.length <= 50

    return render json: { message: "The name can't contain leading/trailing space, or can't contain the following characters: < > ; |" }, status: 422 unless params[:name].match?(/^(?!\s)(?!.*[<>;|])[\u0020-\u007E\u00C7]+$/)

    return render json: { message: "Please enter valid azure cloud." }, status: 422 unless params[:azure_cloud].present? && params[:azure_cloud].eql?('AzureCloud')

    return render json: { message: "Please provide valid subscription details." }, status: 422 if params[:subscription_id].blank? && params[:azure_account_type].eql?('ss') && params[:export_configuration] && params[:export_configuration][:scope].eql?('Subscription')
    
    return render json: { message: 'Invoice date must be between 1 and 31' }, status: 422 if params[:enable_invoice_date] && !(1..31).include?(params[:invoice_date].to_i)
    
    if params[:id].present?
      adapter = current_tenant.adapters.azure_adapter.find_by_id(params[:id])
      return render json: { message: "Couldn't find Adapter with id=#{params[:id]}." }, status: 404 unless adapter.present?
    end

    if params[:azure_office_365_services].present?
      invalid_office_services = validate_azure_office_365_services
      return render json: { message: "Please provide valid office 365 services. Invalid office 365 services are: #{ invalid_office_services.map { |item| "'#{item}'" }.to_sentence }" }, status: 422 if invalid_office_services.present?
    end

  end

end
