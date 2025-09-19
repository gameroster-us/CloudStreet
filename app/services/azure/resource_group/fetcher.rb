class Azure::ResourceGroup::Fetcher < CloudStreetService

  extend CommonServiceHelper

  class << self
    def fetch(params, current_tenant, &block)
      adapter_group_id = params.delete(:adapter_group_id)
      params[:adapter_id] = adapter_ids_from_filter(current_tenant, 'azure', params[:adapter_id], adapter_group_id)
      resource_groups = Azure::ResourceGroup.where(adapter_id: params[:adapter_id]).active.order_by_name
      resource_groups = resource_groups.filter_resource_group(current_tenant.azure_resource_group_ids)
      total_records = resource_groups.count
      resource_groups = resource_groups.paginate({ page: params[:page], per_page: params[:per_page] }) if !params[:page].blank? && !params[:per_page].blank?
      response = { resource_groups: resource_groups, total_records: total_records }
      status Status, :success, response, &block
    rescue StandardError => e
      status Status, :error, e.message, &block
    end

  end

end
