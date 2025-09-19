class OrganisationSettingsController < ApplicationController
  authorize_actions_for OrganisationSettingAuthorizer, except: :index

  def index
    authorize_action_with_condition(:index, OrganisationSettingAuthorizer)
    OrganisationSettingsService.show_synchronization_settings(current_account) do |result|
      result.on_success { |settings| respond_with_user_and settings, status: 200, represent_with: OrganisationSettingsRepresenter }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def update
    OrganisationSettingsService.update_synchronization_settings(@user, current_account, synchronization_settings_params) do |result|
      result.on_success   { render body: nil, status: 200 }
      result.on_error     { render body: nil, status: 500 }
      result.on_validation_error { |error_msgs| render status: 422, json: { validation_error: error_msgs } }
    end
  end

  private

  def synchronization_settings_params
    params.permit(:id, :interval, :sync_time, :auto_sync_to_aws, :auto_sync_to_cs_from_aws, adapters: [])
  end
end