class ProviderData::Subnet::AWS
  attr_reader :provider_data
  attr_reader :subnet_id, :vpc_id, :cidr_block, :availability_zone, :map_public_ip_on_launch, :state, :available_ip_address_count, :tag_set

  def initialize(provider_data)
    provider_data = HashWithIndifferentAccess.new(provider_data)
    @provider_data = provider_data
    if provider_data.present? && provider_data.is_a?(Hash)
      @state                      = provider_data['state']
      @vpc_id                     = provider_data['vpc_id']
      @tag_set                    = provider_data['tag_set']
      @subnet_id                  = provider_data['subnet_id']
      @cidr_block                 = provider_data['cidr_block']
      @availability_zone          = provider_data['availability_zone']
      @map_public_ip_on_launch    = provider_data['map_public_ip_on_launch']
      @available_ip_address_count = provider_data['available_ip_address_count']
    end
  end

  def id
    subnet_id
  end

  def to_json
    provider_data.to_json
  end
end
