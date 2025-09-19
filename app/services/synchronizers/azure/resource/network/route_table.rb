module Synchronizers::Azure::Resource::Network::RouteTable

  def fetch_provider_services(adapter, resource_group_name)
    response = adapter.azure_route_tables.list(resource_group_name)
    response = response.with_formatter(Azure::RemoteResourceObject::Network::RouteTable)
    response.on_success do |provider_data|
      return provider_data
    end

    response.on_error do |error_code, error_message, data|
      CSLogger.error "#{error_code} : #{error_message}"
      return []
    end
  end

  def get_primary_connections(adapter_id, resource_group_id, enabled_region_ids)
    query_params  = {adapter_id: adapter_id, azure_resource_group_id: resource_group_id, region_id: enabled_region_ids}
    vnet_id_map   = Hash[Azure::Resource::Network::Vnet.where(query_params).active.pluck(:name,:id)]
    subnet_id_map = Hash[Azure::Resource::Network::Subnet.where(query_params).active.pluck(:name,:id)]

    route_tables = Azure::Resource::Network::RouteTable.where(query_params).active
    route_tables.inject([]) { |memo, rt| memo.concat(rt.build_primary_connection({vnet_id_map: vnet_id_map, subnet_id_map: subnet_id_map})); memo }
  end

end
