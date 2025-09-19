class Api::V2::GCP::AdaptersController < Api::V2::SwaggerBaseController
  include Api::V2::Concerns::ParamsValidator

  before_action :adapter_name_valid, :check_validation, :except => [:index, :remove, :delete_all, :verify_credential]
  before_action :credential_verification, :except => [:index, :remove, :delete_all, :verify_credential]
  before_action :get_tenant_adapter, :only => [:update_normal, :update_billing, :remove]
  before_action :valid_margin_discount, :only => [:create_billing, :update_billing]

  authorize_actions_for Adapter,
  except: [:index],
  actions: {
    create_normal: 'create',
    update_normal: 'update',
    remove: 'delete',
    create_billing: 'create',
    verify_credential: 'read',
    update_billing: 'update',
    delete_all: 'delete'
  }

  def index
    authorize_action_with_condition(:index, Adapter)
    params[:provider_type] = 'Adapters::GCP'
    params[:show_all] =  true
    V2::Swagger::AdapterService.search(current_tenant, params) do |result|
      result.on_success { |adapters| respond_with_user_and adapters, with_buckets: false, represent_with: V2::GCP::AdapterListRepresenter }
      result.not_found  { |message| render json: { message: message }, status: 404 }
      result.on_validation_error { |error| render status: 422, json: { validation_error: error } }
      result.on_error   { |errors| render body: nil, json: { errors: errors } }
    end
  end

  def create_normal
    authorize_action_for Adapter, { account_id: current_account.id }
    params[:adapter_purpose] = "normal"
    AdapterCreator.create(current_organisation,current_tenant, user.id, adapter_params(get_type(params))) do |result|
      result.on_success { |adapter| respond_with_user_and adapter, :with_buckets => true, represent_with: ::V2::GCP::AdapterListObjectRepresenter, location: adapters_url }
      result.on_failed_to_activate { |error| render status: 400, json: cloudstreet_error(:failed_to_activate, [error]) }
      result.on_auth_failure { |error| render status: 400, json: cloudstreet_error(:auth_failure, [error]) }
      result.on_validation_error { |adapter| render status: 422, json: { validation_error: adapter.errors.messages } }
    end
  end

  def create_billing
    authorize_action_for Adapter, { account_id: current_account.id }
    params[:adapter_purpose] = "billing"
    AdapterCreator.create(current_organisation,current_tenant, user.id, adapter_params(get_type(params))) do |result|
      result.on_success { |adapter| respond_with_user_and adapter, :with_buckets => true, represent_with: ::V2::GCP::AdapterListObjectRepresenter, location: adapters_url }
      result.on_failed_to_activate { |error| render status: 400, json: cloudstreet_error(:failed_to_activate, [error]) }
      result.on_auth_failure { |error| render status: 400, json: cloudstreet_error(:auth_failure, [error]) }
      result.on_validation_error { |adapter| render status: 422, json: { validation_error: adapter.errors.messages } }
    end
  end

  def update_billing
    params[:adapter_purpose] = "billing"
    AdapterUpdater.update(user.id, current_tenant, @adapter, adapter_params(get_type(params))) do |result|
      result.on_success do |response|
        respond_to do |format|
          format.any { render json: { success: 'Success! Adapter Updated.' }, status: :ok }
        end
      end
      result.on_failed_to_activate { |error| render status: 400, json: cloudstreet_error(:failed_to_activate, [error]) }
      result.on_auth_failure { |error| render status: 400, json: cloudstreet_error(:auth_failure, [error]) }
      result.on_invalid_state { |error| render status: 400, json: cloudstreet_error(:invalid_state, [error]) }
      result.on_error   { |adapter| respond_with_user_and adapter, status: 422 }
      result.on_validation_error { |adapter| render status: 422, json: { validation_error: adapter.errors.messages } }
    end
  end

  def update_normal
    params[:adapter_purpose] = "normal"
    AdapterUpdater.update(user.id, current_tenant, @adapter, adapter_params(get_type(params))) do |result|
      result.on_success do |response|
        respond_to do |format|
          format.any { render json: { success: 'Success! Adapter Updated.' }, status: :ok }
        end
      end
      result.on_failed_to_activate { |error| render status: 400, json: cloudstreet_error(:failed_to_activate, [error]) }
      result.on_auth_failure { |error| render status: 400, json: cloudstreet_error(:auth_failure, [error]) }
      result.on_invalid_state { |error| render status: 400, json: cloudstreet_error(:invalid_state, [error]) }
      result.on_error   { |adapter| respond_with_user_and adapter, status: 422 }
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

  # POST /gcp/verify_credential
  def verify_credential
    return render json: { message: "Please provide valid adapter purpose." }, status: 422 unless ['normal', 'billing', 'backup'].include?(params[:adapter_purpose])

    params[:type] = 'Adapters::GCP'
    Adapters::CredentialVerifier.call(credential_verifier_params) do |result|
      result.on_success { |response| render json: response }
      result.on_error   { |response| render json: response, status: 422 }
    end
  end

  # DELETE /gcp/adapters/delete_all
  def delete_all
    V2::Swagger::AdapterService.destroy_all(current_account, 'Adapters::GCP') do |result|
      result.on_success { |response| render json: { success: 'All GCP Adapters Deleted Successfully.' }, status: 200 }
      result.not_found  { |message| render json: { message: message }, status: 404 }
      result.on_validation_error { |adapter| render status: 422, json: { validation_error: adapter.errors.messages } }
      result.on_error { |adapter| render body: nil, status: 500, json: { validation_error: adapter } }
    end
  end

private
  def credential_verification
    params[:type] = 'Adapters::GCP'
    Adapters::CredentialVerifier.call(credential_verifier_params) do |result|
      result.on_error   { |response| render json: response, status: 422 }
    end
  end

  def adapter_params(klass)
    permits = [:type, :name, :adapter_purpose, :dataset_id, :gcp_access_keys, :is_linked_account, :table_name]
    permits << :margin_discount_calculation if current_organisation.parent_organisation?
    permits << klass.permits
    params.permit(permits).to_h
  end

  def get_type(params)
    fail "no tizzype yo" unless params[:type]

    klass = ActionController::Base.helpers.sanitize(params[:type])
    klass = klass.safe_constantize rescue ''
  end

  def credential_verifier_params
    params.permit(:type, :adapter_id, :adapter_purpose, :gcp_access_keys, :dataset_id, :table_name, :gcp_linked_account)
  end

  def get_tenant_adapter
    @adapter = current_tenant.adapters.gcp_adapter.find(params[:id])
  rescue ActiveRecord::RecordNotFound => e
    render json: { message: "Couldn't find Adapter with id=#{params[:id]}" }, status: 404
  end

  def check_validation
    if params[:id].present?
      adapter = current_tenant.adapters.gcp_adapter.find_by_id(params[:id])
      return render json: { message: "Couldn't find Adapter with id=#{params[:id]}." }, status: 404 unless adapter.present?
    end
  end
end
