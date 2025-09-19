class Azure::RemoteResourceObject::Web::AppService < Struct.new(:provider_data, :name, :provider_id, :sku, :kind, :hostNames, :server_farm_id, :status, :tags)

  include Azure::RemoteResourceObject::Utils::TagParser

  def get_resource_table_attributes
    app_service_plan = get_app_service_plan(server_farm_id)
    {
      name: name,
      provider_id: provider_id,
      provider_data: provider_data,
      sku: sku,
      kind: kind,
      hostnames: hostNames,
      app_service_plan: app_service_plan,
      tags: parse_tags,
      status: status,
      state: "created"
    }
  end

  def self.parse_from_json(data)
    new(
      data,
      data['name'],
      data['name'],
      data['properties']['sku'] || '',
      data['kind'],
      data['properties']['hostNames'] || [],
      data['properties']['serverFarmId'],
      data['properties']['state'],
      data['tags']
    )
  end

  def get_app_service_plan(server_farm_id)
    server_farm_id.split('serverfarms/').last
  end
end
