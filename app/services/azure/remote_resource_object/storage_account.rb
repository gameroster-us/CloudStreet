class Azure::RemoteResourceObject::StorageAccount < Struct.new(:provider_data, :name, :provider_id, :sku, :kind, :primary_endpoints, :primary_location, :status_of_primary, :status_of_secondary, :secondary_location, :secondary_endpoints, :creation_time, :encryption, :access_tier, :enable_https_traffic_only, :network_rule_set, :tags)

  include Azure::RemoteResourceObject::Utils::TagParser

  def get_resource_table_attributes
    {
      name: name,
      provider_id: provider_id,
      provider_data: provider_data,
      sku: sku,
      storage_type: kind,
      primary_endpoints: primary_endpoints,
      primary_location: primary_location,
      status_of_primary: status_of_primary,
      status_of_secondary: status_of_secondary,
      secondary_location: secondary_location,
      secondary_endpoints: secondary_endpoints,
      creation_time: creation_time,
      encryption: encryption,
      access_tier: access_tier,
      enable_https_traffic_only: enable_https_traffic_only,
      network_rule_set: network_rule_set,
      tags: parse_tags,
      state: "created"
    }
  end

  def self.parse_from_json(data)
    new(
      data,
      data["name"],
      data['name'],
      (data["sku"] || {}),
      data["kind"],
      (data["primary_endpoints"] || []),
      data["primary_location"],
      data["status_of_primary"],
      data["status_of_secondary"],
      data["secondary_location"],
      data["secondary_endpoints"],
      data["creation_time"],
      data["encryption"],
      data["access_tier"],
      data["enable_https_traffic_only"],
      data["network_rule_set"],
      (data["tags"] || {})
    )
  end

end
