module Synchronizers::Azure::Resource::Network::Subnet

  def sync(adapter, resource_group, enabled_region_map, remote_objects)
    deactive_deleted_resources(adapter.id, enabled_region_map.values, resource_group.id, remote_objects.map(&:provider_id))

    existing_resources = get_existing_resources(adapter.id, enabled_region_map.values, resource_group.id)

    builder_params = {
      adapter_id: adapter.id,
      resource_group_id: resource_group.id,
      enabled_region_map: enabled_region_map,
      remote_objects: remote_objects,
      existing_resources: existing_resources,
      resource_klass: self.to_s
    }
    resources = Azure::Resource::Builder.call(**builder_params)
    Azure::Resource::Importer.call(resources)
  end

  def get_primary_connections(adapter_id, resource_group_id, enabled_region_ids)
    query_params  = {adapter_id: adapter_id, azure_resource_group_id: resource_group_id, region_id: enabled_region_ids}
    vnet_id_map   = Hash[Azure::Resource::Network::Vnet.where(query_params).active.pluck(:name,:id)]

    subnets = Azure::Resource::Network::Subnet.where(query_params).active
    subnets.inject([]) { |memo, subnet| memo.concat(subnet.build_primary_connection({vnet_id_map: vnet_id_map})); memo }
  end

end
