require './app/models/sa_recommendations/azure.rb'
class SaRecommendationsController < ApplicationController

  before_action :get_provider_name, only: [:create]
  authorize_actions_for SaRecommendation
  authority_actions(create: 'create', show: 'read',
                    update: 'update', destroy: 'delete',
                    bulk_update: 'update', task_history: 'manage')

  def create
    SaRecommendationService.create(@provider,recommendation_params, @user, current_account, current_tenant) do |result|
      result.on_success do |response|
        SaRecommendationNotifierWorker.perform_async({sa_recommendation_ids: response[:sa_recommendations].pluck(:id), host: params[:host], tenant_id: current_tenant.id, current_user_id: @user.id}) if response[:sa_recommendations].present?
        respond_to do |format|
          format.any { render json: response.to_json, status: :ok }
        end
      end
      result.on_validation_error { |errors| render status: 422, json: cloudstreet_error(:validation_error, errors) }
      result.on_error   { |errors| render json: { errors: errors }, status: 500 }
    end
  end

  def update
    @record = current_tenant.sa_recommendations.find_by(id: params[:id])
    SaRecommendationService.update(recommendation_params, @record, current_tenant, @user) do |result|
      result.on_success do |response|
        if response["state"].eql?("completed")
          Notification.get_notifier.sa_recommendation_completed(response["id"], params[:host])
        else
          SaRecommendationNotifierWorker.perform_async({sa_recommendation_ids: [response.id], host: params[:host], tenant_id: current_tenant.id, current_user_id: @user.id})
        end
        respond_to do |format|
          format.any { render json: response.to_json, status: :ok }
        end
      end
      result.on_validation_error { |errors| render status: 422, json: cloudstreet_error(:validation_error, errors) }
      result.on_error   { |errors| render json: { errors: errors }, status: 500 }
      result.on_unauthorized {|msg| render status: 422, json: { message: msg }}
      result.not_found  { |errors| render json: { errors: errors }, status: 404 }
    end
  end

  def destroy
    SaRecommendationService.delete(params, current_tenant, @user) do |result|
      result.on_success { |response| render json: response, status: 200 }
      result.on_validation_error { |errors| render status: 422, json: cloudstreet_error(:validation_error, errors) }
      result.on_error { |errors| render json: { errors: errors }, status: 500 }
      result.not_found  { |errors| render json: { errors: errors }, status: 404 }
    end
  end

  def task_history
    SaRecommendationService.task_history(params, current_tenant) do |result|
      result.on_success { |response| respond_with response[:task_histories], user_options: { current_user: @user, total_records: response[:total_records] }, represent_with: SaRecommendations::TaskListRepresenter}
      result.on_error { |errors| render json: { errors: errors }, status: 500 }
      result.not_found  { |errors| render json: { errors: errors }, status: 404 }
    end
  end

  def bulk_update
    SaRecommendationService.bulk_update(params, current_tenant, @user) do |result|
      result.on_success do |response|
        sa_recommendation_ids = response.pluck(:id)
        response.each do |sa_recommendation|
          if sa_recommendation["state"].eql?("completed")
            Notification.get_notifier.sa_recommendation_completed(sa_recommendation["id"], params[:host])
            sa_recommendation_ids.delete(sa_recommendation["id"])
          end
        end
        SaRecommendationNotifierWorker.perform_async({sa_recommendation_ids: sa_recommendation_ids, host: params[:host], tenant_id: current_tenant.id, current_user_id: @user.id}) if sa_recommendation_ids.present?

        respond_to do |format|
          format.any { render json: response.to_json, status: :ok }
        end
      end
      result.on_validation_error { |errors| render status: 422, json: cloudstreet_error(:validation_error, errors) }
      result.on_error   { |errors| render json: { errors: errors }, status: 500 }
      result.on_unauthorized {|msg| render status: 422, json: { message: msg }}
      result.not_found  { |errors| render json: { errors: errors }, status: 404 }
    end
  end


  private

  def recommendation_params
    params.permit(:state, :assigner_comment, :assignee_comment, :additional_comment, :adapter_id, :user_id, :category, :service_type, :assign_to => {}, :data =>[:adapter_id, :provider_id, :key, :instance_id, :azure_resource_url])
  end


  def get_provider_name
    provider = ActionController::Base.helpers.sanitize(params[:provider_type])
    @provider = (provider.downcase.eql?('azure') ? provider.capitalize : provider.upcase) rescue nil
  end
end
