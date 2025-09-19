module Synchronizers::Azure::Resource::Database::SQL::ElasticPool
  def fetch_provider_services(adapter, resource_group_name, sql_server_name)
    response = adapter.azure_sql_server.list_elastic_pools_by_server(resource_group_name, sql_server_name)
    response = response.with_formatter(Azure::RemoteResourceObject::Database::SQL::ElasticPool)
    response.on_success do |provider_data|
      provider_data = provider_data.reject { |data| data.name.eql?('master') }
      return provider_data.each { |data| data.sql_server_name = sql_server_name }
    end

    response.on_error do |error_code, error_message, data|
      CSLogger.error "#{error_code} : #{error_message}"
      return []
    end
  end

  def sync(adapter, resource_group, enabled_region_map, sql_server_remote_objects)
    remote_objects = sql_server_remote_objects.each_with_object([]) do |sql_server_obj, memo|
      memo.concat(fetch_provider_services(adapter, resource_group.name, sql_server_obj.name))
    end
    deactive_deleted_resources(adapter.id, enabled_region_map.values, resource_group.id, remote_objects.map(&:provider_id))
    return if remote_objects.blank?

    existing_resources = get_existing_resources(adapter.id, enabled_region_map.values, resource_group.id)

    builder_params = {
      adapter_id: adapter.id,
      resource_group_id: resource_group.id,
      enabled_region_map: enabled_region_map,
      remote_objects: remote_objects,
      existing_resources: existing_resources,
      resource_klass: to_s
    }
    resources = Azure::Resource::Builder.call(builder_params)
    Azure::Resource::Importer.call(resources)
    remote_objects
  end
end
