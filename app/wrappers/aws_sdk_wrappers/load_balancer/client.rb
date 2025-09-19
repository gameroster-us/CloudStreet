class AWSSdkWrappers::LoadBalancer::Client < AWSSdkWrappers::Client
  attr_accessor :client

  def initialize(adapter = nil, region_code = nil,**instance_profile_params)
    attributes = connection_attributes(adapter, region_code, **instance_profile_params)
    @client = Aws::ElasticLoadBalancingV2::Client.new(attributes)
    @response = AWSSdkWrappers::Response.new
  end
end
