# frozen_string_literal: true

# class Api::V2::Vw::BaseController < ActionController::API
class Api::V1::Vw::BaseController < ActionController::API
  wrap_parameters false
  before_action :print_params
  before_action :authenticate_vdc_request!

  rescue_from ActiveRecord::RecordNotFound,  with: :record_not_found
  rescue_from PG::InvalidTextRepresentation, with: :record_not_found
  rescue_from PG::ConnectionBad,             with: :server_error
  rescue_from Exception,                     with: :server_error

  include Roar::Rails::ControllerAdditions
  respond_to :json

  def authenticate_vdc_request!
    unless user_id_in_token?
      SlackService.notify(channel_name: SLACK_VMWARE_ALERT_CHANNEL, error_class: 'Api::V1::Vw::BaseController:authenticate_vdc_request', error_message: 'user_id not in token', error_backtrace: '', parameters: { user_id: auth_token[:subdomain] }) if ENV['SLACK_API_TOKEN']
      return unauthorized_user
    end 

    @user = User.find_by(id: auth_token[:user_id])
    @current_organisation = Organisation.find_by_subdomain(auth_token[:subdomain])
    if @user.blank? || @current_organisation.blank?
      SlackService.notify(channel_name: SLACK_VMWARE_ALERT_CHANNEL, error_class: 'Api::V1::Vw::BaseController:authenticate_vdc_request', error_message: 'user or current_organisation is blank', error_backtrace: '', parameters: { subdomain: auth_token[:subdomain] }) if ENV['SLACK_API_TOKEN']
      return unauthorized_user
    end
    @current_account = @current_organisation.try(:account)
    @current_tenant = @current_organisation.tenants.default
    @adapter = Adapters::VmWare.find_by(id: auth_token[:adapter_id])
    if @adapter.blank? && !skip_for_false_hb_alarm.include?(auth_token[:adapter_id])
      #SlackService.notify(channel_name: SLACK_VMWARE_ALERT_CHANNEL, error_class: 'Api::V1::Vw::BaseController:authenticate_vdc_request', error_message: 'adapter is not present or deleted !', error_backtrace: '', parameters: { adapter_id: auth_token[:adapter_id], subdomain: auth_token[:subdomain] }) if ENV['SLACK_API_TOKEN']
      return unauthorized_user 
    end

    true

  rescue StandardError => e
    SlackService.notify(channel_name: SLACK_VMWARE_ALERT_CHANNEL, error_class: 'Api::V1::Vw::BaseController:authenticate_vdc_request', error_message: e.message.to_s, error_backtrace: e.backtrace, parameters: { adapter_id: auth_token[:adapter_id], subdomain: auth_token[:subdomain] }) if ENV['SLACK_API_TOKEN']
  end

  def skip_for_false_hb_alarm
    [
      '15dd94db-6e1d-4702-8218-e5b316f0f076', #"HANSEN-VMWARE-HSNDON-VC03"
      'd6895c03-e2d9-49a3-b7ff-1d5512502736', #"sms"
      'cdc587c1-4df6-4470-bbdb-f05592313ffd', #"int-ywfrankfurt"
      'd6895c03-e2d9-49a3-b7ff-1d5512502736' #"tgray"
    ]
  end

  def record_not_found(error)
    render json: { message: error.message }, status: 404
  end

  def unauthorized_user
    render json: { error: 'Not authorized' }, status: 401
  end

  def current_vm_ware_adapter
    @adapter
  end

  def current_vmware_adapter_id
    current_tenant.vm_ware_tenant_adapters.where(organisation_id: current_organisation.id).order(updated_at: :desc).first.try(:adapter_id)
  end

  def server_error(error)
    puts error.message
    puts error.backtrace
    render json: { message: 'something went wrong!!!' }, status: 500
  end

  def respond_with_user_and(*resources, &block)
    options = resources.size == 1 ? {} : resources.extract_options!

    options[:current_user]    = user
    options[:current_account] = current_account
    resources.push(options)

    respond_with(*resources, &block)
  end

  def fetch_currency_rates
    unless @klass.eql?('GCP')
      get_service_adviser_billing_adapter
      @rates = CSIntegration::CostConversion.check_and_find_currency_rate(current_tenant, @billing_adapter, params[:currency], @klass.downcase)
      rate = CSIntegration::CostConversion.check_for_rate_month(@rates, params)
      return render json: {message: "no currency conversion rates available for '#{params[:currency]}' "} if rate.blank? && params[:currency].present?
    end
  end

  private

  def print_params
    CSLogger.info('==========================================================')
    CSLogger.info(params)
    CSLogger.info('==========================================================')
  end

  def http_token
    @http_token ||= request.headers['Authorization'].split(' ').last if request.headers['Authorization'].present?
  end

  def auth_token
    @auth_token ||= (AuthToken.decode(http_token) || {}).deep_symbolize_keys
  end

  def user_id_in_token?
    http_token && auth_token && auth_token[:user_id]
  end

  def page_params
    params.permit(:page_size, :page_number)
  end

  def authorize_action_with_condition(controller_action_name, klass_name)
    unless params['check_permission'].eql?('false')
      self.class.add_actions(controller_action_name => 'read')
      authorize_action_for(klass_name)
    end
  end

end
