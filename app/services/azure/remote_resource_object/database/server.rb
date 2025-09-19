class Azure::RemoteResourceObject::Database::Server < Struct.new(:provider_data, :name, :provider_id, :sku, :version, :ssl_enforcement, :domain_name, :storage_profile, :db_status, :tags)

  include Azure::RemoteResourceObject::Utils::TagParser

  def get_resource_table_attributes
    {
      name: name,
      provider_id: provider_id,
      provider_data: provider_data,
      sku: sku,
      version: version,
      ssl_enforcement: ssl_enforcement,
      domain_name: domain_name,
      backup_retention_days: storage_profile["backup_retention_days"],
      storage_size_in_mb: storage_profile["storage_mb"],
      db_status: db_status,
      tags: parse_tags,
      state: "created"
    }
  end

  def self.parse_from_json(data)
    new(
      data,
      data["name"],
      data['name'],
      data["sku"],
      data["version"],
      data["ssl_enforcement"],
      data["fully_qualified_domain_name"],
      (data["storage_profile"] || {}),
      data["user_visible_state"],
      (data["tags"] || {})
    )
  end

end
