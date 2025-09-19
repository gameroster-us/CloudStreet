# Synchronizers Container AKS
module Synchronizers::Azure::Resource::Container::AKS
  def fetch_provider_services(adapter, resource_group_name)
    response = adapter.azure_aks.list(resource_group_name)
    response = response.with_formatter(Azure::RemoteResourceObject::Container::AKS)
    response.on_success do |provider_data|
      return provider_data
    end

    response.on_error do |error_code, error_message, _data|
      CSLogger.error "#{error_code} : #{error_message}"
      return []
    end
  end
end
