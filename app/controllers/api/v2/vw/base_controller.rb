# frozen_string_literal: true

# class Api::V2::Vw::BaseController < ActionController::API
class Api::V2::Vw::BaseController < Api::V2::ApiBaseController
  before_action :print_params

  def authenticate_request!
    super
    @adapter = Adapters::VmWare.find_by(id: auth_token[:adapter_id])
    return unauthorized_user if @adapter.blank?

    true
  end

  private

  def print_params
    CSLogger.info('==========================================================')
    CSLogger.info(params)
    CSLogger.info('==========================================================')
  end

  def current_vm_ware_adapter
    @adapter
  end
end
