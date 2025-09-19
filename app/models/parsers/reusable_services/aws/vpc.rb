class Parsers::ReusableServices::AWS::Vpc
  def parse_for_filter(service)
    filter = {
      adapter_id: service.adapter_id,
      account_id: service.account_id,
      region_id: service.region_id,
      uniq_provider_id: service.data["uniq_provider_id"]
    }.compact
    filter.merge!({vpc_id: service.data['vpc_id']}) unless service.data['uniq_provider_id'].present?
    filter
  end

  def parse_for_create(service)
    {
      name: service.name.downcase,
      provider_id: service.attributes["provider_id"],
      uniq_provider_id: service.data["uniq_provider_id"],
      cidr: service.data['cidr_block'],
      enable_dns_resolution: (service.data['enable_dns_resolution'] || false),
      tenancy: service.data['tenancy'] || 'default',
      region_id: service.region_id,
      adapter_id: service.adapter_id,
      type: "Vpcs::AWS",
      state: 'pending',
      internet_attached: service.data['internet_attached'],
      enable_dns_hostnames: service.data['enable_dns_hostnames'],
      amazon_provided_ipv_6_cidr_block: (service.data['amazon_provided_ipv_6_cidr_block'] || false)
    }
  end

  def parse_for_update(service)
    CSLogger.info "service----#{service.inspect}-----in the updator"
    {
      name: service.name.downcase,
      provider_data: service.provider_data,
      provider_id: service.attributes["provider_id"],
      vpc_id: service.attributes['provider_id'],
      state: 'available'
    }
  end
end