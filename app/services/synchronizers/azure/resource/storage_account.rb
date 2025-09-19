module Synchronizers::Azure::Resource::StorageAccount

  def fetch_provider_services(adapter, resource_group_name)
    response = adapter.azure_storage_account.list_by_resource_group(resource_group_name)
    response = response.with_formatter(Azure::RemoteResourceObject::StorageAccount)
    response.in_hash.on_success do |provider_data|
      return provider_data
    end

    response.on_error do |error_code, error_message, data|
      CSLogger.error "#{error_code} : #{error_message}"
      return []
    end
  end

end
