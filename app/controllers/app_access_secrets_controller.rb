class AppAccessSecretsController < ApplicationController

  before_action :set_app_access_secret, only: [:enable_disable, :destroy]
  skip_after_action :record_user_activity

  def index
    AppAccessSecret::Fetcher.exec(current_organisation, @user) do |result|
      result.on_success { |app_secret_keys| respond_with app_secret_keys, represent_with: AppAccessSecretsRepresenter }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def create
    AppAccessSecret::Creator.exec(current_account, @user, app_secrets_params) do |result|
      result.on_success { |response| render json: response }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def enable_disable
    AppAccessSecret::Updater.exec(@app_access_secret, app_secrets_params[:enabled]) do |result|
      result.on_success { |app_secret_key| respond_with app_secret_key, represent_with: AppAccessSecretsRepresenter }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def destroy
    AppAccessSecret::Deleter.exec(@app_access_secret) do |result|
      result.on_success { render json: {}, status: 200 }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  private

  def set_app_access_secret
    @app_access_secret = AppAccessSecret.where(id: params[:id],user_id: @user.id, organisation_id: current_organisation.id).first
    render json: {message: "Record not found."}, status: 404 if @app_access_secret.blank?
  end

  def app_secrets_params
    params.permit(:description, :token_expires, :enabled)
  end

end
