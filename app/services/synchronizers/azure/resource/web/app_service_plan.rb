module Synchronizers::Azure::Resource::Web::AppServicePlan

  def fetch_provider_services(adapter, resource_group_name)
    response = adapter.azure_app_service_plan.list(resource_group_name)
    response = response.with_formatter(Azure::RemoteResourceObject::Web::AppServicePlan)
    response.on_success do |provider_data|
      CSLogger.info "API return plans resource_group_name -#{resource_group_name} - #{provider_data.pluck('name')}"
      return provider_data
    end

    response.on_error do |error_code, error_message, data|
      CSLogger.error "#{error_code} : #{error_message}"
      return []
    end
  end
end
