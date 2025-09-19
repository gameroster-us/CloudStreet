class Vpcs::Azure < Vpc
  validates_format_of :name, with: /\A[a-zA-Z0-9][-a-zA-Z0-9]*\z/

  def create
    # Todo :: dev.cloudstreet.com is in test env so need to run the functionality,
    # in future we run rspec then need to change dev.cloudstreet.com's environment
    # return save if Rails.env.test?
    affinity_group_name = create_affinity_group
    vn_agent = adapter.connection_vn

    # create VN on Azure
    vn_agent.set_network_configuration(name, affinity_group_name, cidr_arr, { subnet: [default_subnet_map] })
    # Find created VN from Azure
    remote_vpc = vn_agent.list_virtual_networks.find { |vn| vn.name == name }

    self.vpc_id = remote_vpc.id
    self.provider_data = remote_vpc.to_json
    save
  end

  def is_cidr_format_valid?
    cidr_list = cidr.split(',') rescue nil
    if cidr_list.blank?
      errors.add(:cidr, 'please add valid comma seprated list of cidr')
      return false
    end

    cidr_list.each do |cidr_string|
      parsed_cidr = NetAddr::CIDRv4.create(cidr_string) rescue nil
      if parsed_cidr.blank?
        errors.add(:cidr, "invalid format of cidr: #{cidr_string}")
        return false
      end
    end

    true
  end

  def cidr_arr
    @cidr_arr ||= cidr.split ','
  end

  private

  def default_subnet_map
    ip_address, cidr = cidr_arr.first.split '/'
    { name: "#{name}-default-subnet",  ip_address: ip_address,  cidr: cidr }
  end

  def create_affinity_group
    affinity_group_name = "#{name}-affinity-group"
    begin
      adapter.connection_base.create_affinity_group(affinity_group_name, region.code, affinity_group_name)
    rescue Azure::Error::Error => e
      if e.status_code == 409
        CSLogger.error('got conflict while creating affinity-group hence skipping using existing created affinity-group')
      else
        raise e
      end
    end
    affinity_group_name
  end
end
