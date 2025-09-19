# frozen_string_literal: false

# Controller for service group policy management
class ServiceGroupPoliciesController < ApplicationController

  authorize_actions_for ServiceGroupPolicy
  authority_actions(index: 'read', create: 'create', show: 'read',
                    update: 'update', destroy: 'delete', enable: 'update',
                    disable: 'update')
  def index
    ServiceGroupPolicies::List.call(current_tenant, list_params) do |result|
      result.on_success do |response|
        respond_with_user_and(response[:group_policies],
                              { total_records: response[:total_records],
                                represent_with: ServiceGroupPolicies::ListRepresenter })
      end
      result.on_error { |errors| render json: { errors: errors }, status: 500 }
    end
  end

  def create
    ServiceGroupPolicies::Creator.call(current_tenant, create_params) do |result|
      result.on_success do |service_group_policy|
        respond_with_user_and(service_group_policy,
                              represent_with: ServiceGroupPolicies::ServiceGroupPolicyRepresenter)
      end
      result.on_validation_error { |errors| render status: 422, json: cloudstreet_error(:validation_error, errors) }
      result.on_error   { |errors| render json: { errors: errors }, status: 500 }
    end
  end

  def show
    ServiceGroupPolicies::List.show(current_tenant, group_policy_show_params) do |result|
      result.on_success do |service_group_policy|
        respond_with_user_and(service_group_policy, represent_with: ServiceGroupPolicies::ServiceGroupPolicyRepresenter)
      end
      result.on_error { |errors| render json: { errors: errors }, status: 500 }
    end
  end

  def update
    service_group_policy = current_tenant.service_group_policies.find(params[:id])
    ServiceGroupPolicies::Updater.call(current_tenant, service_group_policy, update_params) do |result|
      result.on_success { |group_policy| render json: group_policy, status: 200 }
      result.on_validation_error { |errors| render status: 422, json: cloudstreet_error(:validation_error, errors) }
      result.on_error   { |errors| render json: { errors: errors }, status: 500 }
    end
  rescue StandardError => e
    render(json: { errors: e }, status: 500)
  end

  def destroy
    service_group_policy = current_tenant.service_group_policies.find(params[:id])
    ServiceGroupPolicies::Deleter.call(service_group_policy, delete_params) do |result|
      result.on_success { |response| render json: response, status: 200 }
      result.on_error   { |errors| render json: { errors: errors }, status: 500 }
    end
  end

  def enable
    service_group_policy = current_tenant.service_group_policies.find(params[:id])
    ServiceGroupPolicies::Updater.enable(service_group_policy) do |result|
      result.on_success { |group_policy| render json: group_policy, status: 200 }
      result.on_validation_error { |errors| render status: 422, json: cloudstreet_error(:validation_error, errors) }
      result.on_error   { |errors| render json: { errors: errors }, status: 500 }
    end
  end

  def disable
    service_group_policy = current_tenant.service_group_policies.find(params[:id])
    ServiceGroupPolicies::Updater.disable(service_group_policy) do |result|
      result.on_success { |group_policy| render json: group_policy, status: 200 }
      result.on_validation_error { |errors| render status: 422, json: cloudstreet_error(:validation_error, errors) }
      result.on_error { |errors| render json: { errors: errors }, status: 500 }
    end
  end

  private

  def create_params
    params.require(:service_group_policy).permit(:name,
                                                 :description,
                                                 :type,
                                                 :billing_adapter_id,
                                                 :tag,
                                                 custom_data: %i[key value])
  end

  def update_params
    params.require(:service_group_policy).permit(:name,
                                                 :description,
                                                 custom_data: %i[key value])
  end

  def group_policy_show_params
    params.permit(:id)
  end

  def list_params
    params.permit(:state, :billing_adapter_id, :name, :type, :page_size, :page_number, :sort_by, :sort_order)
  end

  def delete_params
    params.permit(:associated_group_delete_flag)
  end

end
