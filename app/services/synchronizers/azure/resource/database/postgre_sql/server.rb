module Synchronizers::Azure::Resource::Database::PostgreSQL::Server

  def fetch_provider_services(adapter, resource_group_name)
    response = adapter.azure_postgresql_server.list(resource_group_name)
    response = response.with_formatter(Azure::RemoteResourceObject::Database::PostgreSQL::Server)
    response.on_success do |provider_data|
      return provider_data
    end

    response.on_error do |error_code, error_message, data|
      CSLogger.error "#{error_code} : #{error_message}"
      return []
    end
  end

end
