class IntegrationsController < ApplicationController
  skip_before_action :authenticate, only: [:microsoft_identity_association]

  def supported_modules_list
    Integrations::IntegrationService.supported_modules_list do |result|
      result.on_success { |modules| render status: 200, json: { modules: modules } }
      result.on_error { |error| render status: 500, json: { modules: [] } }
    end
  end

  def teams_supported_modules_list
    Integrations::IntegrationService.teams_supported_modules_list do |result|
      result.on_success { |modules| render status: 200, json: { modules: modules } }
      result.on_error { |error| render status: 500, json: { modules: [] } }
    end
  end

  def delete_all_workspaces
    Integrations::WorkspaceService.delete_all_workspaces(@organisation, @user, current_account) do |result|
      result.on_success { |modules| render status: 200, json: { modules: modules } }
      result.on_error { |error| render status: 500, json: { modules: [] } }
    end
  end

  def microsoft_identity_association
    send_file(
      "#{Rails.root}/public/microsoft-identity-association.json",
      filename: "microsoft-identity-association.json",
      type: "application/json"
    )
  end
end
