# frozen_string_literal: true

# Class to fetch tag key values
class TaskService::Fetcher::TagKeyValueFetcher::Azure < CloudStreetService

  AZURE_SERVICE_TYPE_FILTERS= {
    "idle_vm" => "Azure::Resource::Compute::VirtualMachine",
    "idle_stopped_vm" => "Azure::Resource::Compute::VirtualMachine",
    "idle_databases" => "Azure::Resource::Database",
    "idle_disks" => "Azure::Resource::Compute::Disk",
    "idle_lbs" => "Azure::Resource::Network::LoadBalancer",
    "unassociated_lbs" => "Azure::Resource::Network::LoadBalancer",
    "unassociated_public_ips"=> "Azure::Resource::Network::PublicIPAddress",
    "unattached_disks" => "Azure::Resource::Compute::Disk",
    "unused_snapshots" => "Azure::Resource::Compute::Snapshot",
    "idle_elastic_pools" => "Azure::Resource::Database::SQL::ElasticPool",
    "idle_blob_services" => "Azure::Resource::Resource::Blob",
    "idle_app_service_plans" => "Azure::Resource::Web::AppService",
    "unused_app_service_plans" => "Azure::Resource::Web::AppServicePlan"
  }

  class << self
    def get_all(params, account, current_tenant)
      general_setting = account.general_setting
      query_adapters = params['adapter_groups'].present? ? ServiceGroup.adapterids_from_adapter_group(params['adapter_groups'].split(',')) : get_adapters(params, current_tenant)
      query_azure_resource_group = get_azure_ressource_group_id(params, query_adapters, current_tenant)
      service_types = params['recommendation_policy_id'].present? ? get_recommendation_task_service_type(params) : params["service_types"].split(',')
      modified_service_types = TaskService::Fetcher::CommonMethod.filter_and_add_service_types(service_types)
      query_params = {
        type: modified_service_types,
        adapter_id: query_adapters,
        region_id: params['regions'].split(','),
        azure_resource_group_id: query_azure_resource_group
      }

      services = Azure::Resource.where(query_params).active
      stopped_deallocated_vm_ids = services.virtual_machines.stopped_deallocated_vm.ids
      services = services.where.not(id: stopped_deallocated_vm_ids)
      .exclude_aks_resource_group_services
      .exclude_databricks_resource_group_services
      return [] unless services.present?

      service_tags = services.map { |service| service.provider_data && service.provider_data.try(:[], 'tags').try(:keys) }.compact.flatten.uniq
      return [] unless service_tags.present?

      if params['key'].blank?
        filtered_service_tags = service_tags.select { |a| a.try(:downcase).match(params['query'].downcase) } rescue []
        filtered_service_tags = TaskService::Fetcher::CommonMethod.tenant_wise_tags(filtered_service_tags, current_tenant&.tags&.[]('tag_key'), general_setting&.is_tag_case_insensitive) if current_tenant&.tags.present?
        general_setting&.is_tag_case_insensitive ? filtered_service_tags.map(&:downcase).uniq : filtered_service_tags
      else
        service_tag_values = if general_setting&.is_tag_case_insensitive
          services.map { |service| service.provider_data['tags']&.map { |k, v| v if k.downcase.eql?(params[:key].downcase) } }.flatten.compact.map(&:downcase).uniq
        else
          services.map { |service| service.provider_data['tags'] && service.provider_data['tags'][params['key']] }.flatten.compact.uniq
        end

        service_tag_values = TaskService::Fetcher::CommonMethod.tenant_wise_tags(service_tag_values, current_tenant&.tags&.[]('tag_value'), general_setting&.is_tag_case_insensitive) if current_tenant&.tags.present?
        params[:value].present? ? (service_tag_values.select { |t| t.try(:downcase).match(params[:value].downcase) } rescue []) : service_tag_values
      end
    end

    def get_recommendation_task_service_type(params)
      policy = RecommendationPolicy.find_by(id: params[:recommendation_policy_id])
      policy.services.map { |service_type| AZURE_SERVICE_TYPE_FILTERS[service_type] }.compact
    end

    def get_adapters(params, current_tenant)
      params['adapters'] == "all" ? current_tenant.adapters.where(type:'Adapters::Azure').normal_adapters.available.pluck(:id) : params['adapters'].split(',')
    end

    def get_azure_ressource_group_id(params, query_adapters, current_tenant)
      params['azure_resource_group_id'] == "all" ? Azure::ResourceGroup.where(adapter_id: query_adapters).filter_resource_group(current_tenant.azure_resource_group_ids).active.pluck(:id) : params['azure_resource_group_id'].split(',')
    end
  end
end
