class Azure::RemoteResourceObject::Compute::AvailabilitySet < Struct.new(:provider_data, :name, :provider_id, :sku, :virtual_machines, :platform_update_domain_count, :platform_fault_domain_count, :tags)

  include Azure::RemoteResourceObject::Utils::TagParser

  def get_resource_table_attributes
    {
      name: name,
      provider_id: provider_id,
      provider_data: provider_data,
      sku: parse_sku,
      virtual_machines: parse_virtual_machines,
      platform_update_domain_count: platform_update_domain_count,
      platform_fault_domain_count: platform_fault_domain_count,
      tags: parse_tags,
      state: "created"
    }
  end

  def parse_virtual_machines
    virtual_machines.each_with_object([]) do |vm, memo|
      vm = vm["id"].split("/").last if vm["id"].present?
      memo << vm
    end
  end

  def parse_sku
    sku["name"] rescue sku
  end

  def self.parse_from_json(data)
    new(
      data,
      data["name"],
      data['name'],
      data["sku"],
      (data["virtual_machines"] || []),
      data["platform_update_domain_count"],
      data["platform_fault_domain_count"],
      data["tags"]
    )
  end

end
