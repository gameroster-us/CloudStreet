class Azure::RemoteResourceObject::Blob < Struct.new(:provider_data, :name, :provider_id, :delete_retention_policy, :is_versioning_enabled, :metadata)

  include Azure::RemoteResourceObject::Utils::TagParser

  def get_resource_table_attributes
    {
      name: name,
      provider_id: name,
      provider_data: provider_data,
      data: {storage_account_name: provider_data["storage_account_name"] },
      state: "created"
    }
  end

  def self.parse_from_json(data, storage_ac)
    data = data["value"].first if data.present?
    new(
      data.merge("location" => storage_ac.provider_data["location"], "storage_account_name" => storage_ac.name),
      "#{storage_ac.name}-#{data["name"]}",
      "#{storage_ac.name}-#{data["name"]}",
      (data["delete_retention_policy"] || {}),
      (data["is_versioning_enabled"]),
      (data['sku'] || {})
    )
  end

end
