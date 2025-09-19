# frozen_string_literal: true

# Adapters controller for Reseller Organisation Module
class ChildOrganisation::Reseller::AdaptersController < ApplicationController

  authorize_actions_for ChildOrganisation::Reseller::AdapterAuthorizer, except: %i[available_billing_adapters available_normal_adapters available_adapter_groups]
  include ChildOrganisationHelper
  before_action :can_access_reseller_apis

  def available_billing_adapters
    ChildOrganisation::Reseller::Adapter::Fetcher.available_billing_adapters(current_tenant, billing_adapter_params) do |result|
      result.on_success { |adapters| respond_with_user_and adapters, represent_with: AdaptersBasicInfoRepresenter }
      result.on_error   { |message| render json: { message: message }, status: 500 }
    end
  end

  def available_normal_adapters
    ChildOrganisation::Reseller::Adapter::Fetcher.available_normal_adapters(current_organisation, current_tenant, normal_adapter_params) do |result|
      result.on_success { |adapters| respond_with_user_and adapters, represent_with: AdaptersBasicInfoRepresenter }
      result.on_error   { |message| render json: { message: message }, status: 500 }
    end
  end

  def available_adapter_groups
    ChildOrganisation::Reseller::Adapter::Fetcher.available_adapter_groups(current_account, current_tenant, adapter_group_params) do |result|
      result.on_success { |service_groups| respond_with_user_and service_groups[0], total_records: service_groups[1], selected_service_groups: service_groups[2], represent_with: ServiceGroupsRepresenter }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  # Updates the adapters shared to a child org
  def update
    ChildOrganisation::Reseller::Adapter::Updater.update_shared_adapters(current_account, update_params, user_id: @user.id) do |result|
      result.on_success { render body: nil, status: 204 }
      result.on_validation_error { |errors| render status: 422, json: { message: errors } }
      result.on_error   { |message| render json: { message: message }, status: 500 }
    end
  end

  private

  def billing_adapter_params
    params.permit(:page_number, :page_size, :provider_type, :searchKeyword, :organisation_id)
  end

  def normal_adapter_params
    params.permit(:page_number, :page_size, :provider_type, :searchKeyword, :billing_adapter_id, :type, :organisation_id, :selected_adapter)
  end

  def adapter_group_params
    params.permit(:provider_type, :billing_adapter_id, :type, :organisation_id, :page_number, :page_size, :name, adapter: {})
  end

  def update_params
    params.permit(:id, billing_adapter_ids: [], adapter_group_ids: [], normal_adapters_ids: [], adapter: {})
  end

end
