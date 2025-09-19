class Vpcs::NetworkServiceInfo < Vpc
  attr_accessor :nacl, :existing_subnets, :existing_security_groups, :existing_subnet_groups

  def initialize(args)
    vpc = args[:vpc]
    params = args[:params]
    @nacl                     = vpc.nacl if params[:service] == 'nacl'
    @existing_security_groups = vpc.security_groups if params[:service] == 'security_groups'
    @existing_subnets         = vpc.subnets.each{ |subnet| subnet.environment_count_required = true } if params[:service] == 'subnets'
    @existing_subnet_groups   = vpc.subnet_groups if params[:service] == 'subnet_groups'
  end
end
