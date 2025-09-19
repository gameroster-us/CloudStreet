class Services::Network::LoadBalancer::Rackspace < Services::Network::LoadBalancer
  store_accessor :data, :aws_id, :region

  def provision
    #return if running?

    adapter_info = Adapter.for_type(Adapters::AWS).first

    aws = Fog::AWS::ELB.new(
      aws_access_key_id: adapter_info.access_key_id,
      aws_secret_access_key: adapter_info.secret_access_key,
      region: 'us-east-1'
    )

    puts aws.inspect
    lb = aws.load_balancers.create(id: 'my-el2b', availability_zones: %w(us-east-1a))

    created
    starting
    #
#     'ListenerDescriptions' => [{
#       ''
#   'Listener' => {'LoadBalancerPort' => 80, 'InstancePort' => 80, 'Protocol' => 'HTTP'},
# }])
    lb.wait_for do
      print "."
      ready?
    end

    # aws_id = lb.id
    # region = lb.availability_zones[0]
    running
    save!
    puts "saved"
    puts lb.inspect
    #
    # <Fog::AWS::ELB::LoadBalancer
  #   id="my-el2b",
  #   availability_zones=["us-east-1a"],
  #   created_at=2013-10-05 04:41:42 UTC,
  #   dns_name="my-el2b-1699233222.us-east-1.elb.amazonaws.com",
  #   health_check={"Interval"=>30, "Target"=>"TCP:80", "HealthyThreshold"=>10, "Timeout"=>5, "UnhealthyThreshold"=>2},
  #   instances=[],
  #   source_group={"OwnerAlias"=>"amazon-elb", "GroupName"=>"amazon-elb-sg"},
  #   hosted_zone_name="my-el2b-1699233222.us-east-1.elb.amazonaws.com",
  #   hosted_zone_name_id="Z3DZXE0Q79N41H",
  #   subnet_ids=[],
  #   security_groups=[],
  #   scheme="internet-facing",
  #   vpc_id=nil
  # >
    #
  end
end
