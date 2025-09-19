# frozen_string_literal: true

# Class to fetch resource groups for azure
class TaskService::Fetcher::ResourceGroup < CloudStreetService
  class << self
    def fetch(params, current_tenant, current_account, &block)
      adapter_ids = params['adapter_group_id'].present? ? ServiceGroup.adapterids_from_adapter_group(params['adapter_group_id'].split(',')) : get_azure_adapter_ids(current_tenant, params)
      return status Status, :success, { resource_groups: [], total_records: 0 }, &block if adapter_ids.blank?

      resource_groups = Azure::ResourceGroup.where(adapter_id: adapter_ids).active.order_by_name
      resource_groups = resource_groups.filter_resource_group(current_tenant.azure_resource_group_ids)
      resource_groups = resource_groups.keyword_filter_by_name(params[:keyword_filter_by_name]) if params[:keyword_filter_by_name].present?
      total_records = resource_groups.count
      resource_groups = resource_groups.paginate({ page: params[:page], per_page: params[:per_page] }) if !params[:page].blank? && !params[:per_page].blank?
      response = { resource_groups: resource_groups, total_records: total_records }
      status Status, :success, response, &block
    rescue StandardError => e
      status Status, :error, e.message, &block
    end

    def get_azure_adapter_ids(current_tenant, params)
      params['adapter_id'] == 'all' ? current_tenant.adapters.azure_normal_active_adapters.ids : params['adapter_id'].split(',')
    end
  end
end
