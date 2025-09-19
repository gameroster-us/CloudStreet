# require 'spec_helper'
# 
# describe Services::Network::AutoScaling do
#   before(:all) do
#     @asg = FactoryBot.create(:service, :auto_scaling_aws, :running)
#   end
# 
#   describe "#create_service_interfaces" do
#     before(:each) do
#       @user = FactoryBot.create(:user_iam_role)
#       @adapter = FactoryBot.create(:adapter, :aws, account_id: @user.account_id)
#       @vpc = FactoryBot.create(:service, :vpc)
#       @vpc.find_or_create_default_interface_connections
#       @launch_config = FactoryBot.create(:service, :auto_scaling_configuration_aws, :running, provider_id: 'auto_scaling_configuration')
#       @subnet = FactoryBot.create(:service, :subnet_aws)
#       @subnet.find_or_create_default_interface_connections
#       @az = FactoryBot.create(:service, :availability_zone)
#       @lb = FactoryBot.create(:service, :load_balancer_aws, :running, provider_id: 'load_balancer1')
#       @env = FactoryBot.create(:environment, account_id: @user.account_id, revision: 1.0, default_adapter_id: @adapter.id)
# 
# 
#       @env.services << @vpc
#       @env.services << @asg
#       @env.services << @launch_config
#       @env.services << @subnet
#       @env.services << @az
#       @env.services << @lb
#       @params = {}
#     end
# 
#     it "should create interfaces" do
#       params = @params.merge(availability_zones: @az.id, vpc_zone_identifier: @subnet.id, launch_configuration_name: @launch_config.provider_id, load_balancers: [@lb.provider_id])
# 
#       @asg = Service.find @asg.id
#       allow_any_instance_of(@subnet.class).to receive(:fetch_first_remote_service).and_return(@vpc)
#       @asg.create_service_interfaces(params)
#       expect(@asg.interfaces.pluck(:interface_type)).to include("Protocols::AutoScalingConfiguration", "Protocols::AvailabilityZone", "Protocols::Subnet", "Protocols::LoadBalancer")
#       expect(@asg.interfaces.count).to eq(5)
# 
#     end
# 
#     it "should not increment the autoscaling group when availability_zones is not provided" do
#       params = @params.merge(vpc_zone_identifier: @subnet.id, launch_configuration_name: @launch_config.provider_id, availability_zones: '')
#       @asg = Service.find @asg.id
# 
#       expect(@asg.create_service_interfaces(params)).to eq(nil)
#     end
# 
#     it "should not increment the autoscaling group when vpc_zone_identifier is not provided" do
#       params = @params.merge(vpc_zone_identifier: '', launch_configuration_name: @launch_config.provider_id, availability_zones: @az.id)
#       @asg = Service.find @asg.id
# 
#       expect(@asg.create_service_interfaces(params)).to eq(nil)
#     end
# 
#     it "should not increment the autoscaling group when launch_configuration_name is not provided" do
#       params = @params.merge(vpc_zone_identifier: @subnet.id, launch_configuration_name: '', availability_zones: @az.id)
#       @asg = Service.find @asg.id
# 
#       expect(@asg.create_service_interfaces(params)).to eq(nil)
#     end
#   end
# end
