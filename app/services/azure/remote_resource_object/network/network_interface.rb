class Azure::RemoteResourceObject::Network::NetworkInterface < Struct.new(:provider_data, :name, :provider_id, :ip_configurations, :enable_ipforwarding, :enable_accelerated_networking, :dns_settings, :network_security_group, :tags)

  include Azure::RemoteResourceObject::Utils::TagParser

  def get_resource_table_attributes
    {
      name: name,
      provider_id: provider_id,
      provider_data: provider_data,
      ip_configurations: parse_ip_configurations,
      enable_ipforwarding: enable_ipforwarding,
      enable_accelerated_networking: enable_accelerated_networking,
      dns_settings: dns_settings,
      network_security_group: parse_network_security_group,
      tags: parse_tags,
      state: "created"
    }
  end

  def parse_ip_configurations
    (ip_configurations || []).each_with_object([]) do |ip_configuration, memo|
      ip_configuration = ip_configuration.except("id", "provisioning_state", "etag")
      s = ip_configuration["subnet"]["id"].split("/") rescue []
      ip_configuration["subnet"] = s[-1]
      ip_configuration["vnet"] = s[-3]
      ip_configuration["public_ipaddress"] = ip_configuration["public_ipaddress"]["id"].split("/").last if ip_configuration["public_ipaddress"].present?
      memo << ip_configuration
    end
  end

  def parse_network_security_group
    network_security_group.try(:[], "id") && network_security_group["id"].split("/").last
  end

  def self.parse_from_json(data)
    new(
      data,
      data["name"],
      data['name'],
      (data["ip_configurations"] || []),
      data["enable_ipforwarding"],
      data["enable_accelerated_networking"],
      (data["dns_settings"] || {}),
      data["network_security_group"],
      (data["tags"] || {})
    )
  end

end
