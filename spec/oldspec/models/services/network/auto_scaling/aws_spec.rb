# require 'spec_helper'
# 
# describe Services::Network::AutoScaling::AWS do
#   before(:all) do
#     @vpc = FactoryBot.create(:vpc)
#     @launch_config = FactoryBot.create(:service, :auto_scaling_configuration, :running, vpc: @vpc)
#     @launch_config = Service.find(@launch_config.id)
#     @launch_config.find_or_create_default_interface_connections
#     asg = FactoryBot.create(:service, :auto_scaling, :running, vpc: @vpc, data:{'launch_configuration_name' => @launch_config.name})
#     @asg = Service.find asg.id
#     @data = {
#       "min_size" => 0,
#       "max_size" => 0,
#       "desired_capacity" => 0,
#       "default_cooldown" => 300,
#       "health_check_type" => "EC2",
#       "health_check_grace_period" => 20,
#       "termination_policies" => "Default"
#     }
#     @updated_data = {
#       "min_size" => 1,
#       "max_size" => 1,
#       "desired_capacity" => 1,
#       "default_cooldown" => 400,
#       "health_check_type" => "ELB",
#       "health_check_grace_period" => 40,
#       "termination_policies" => "ClosestToNextInstanceHour"
#     }
#   end
# 
#   describe 'get_tags' do
#     it "should return the parsed tags" do
#       aws_mock_object = OpenStruct.new(tags: [{"ResourceId"=>"rred", "PropagateAtLaunch"=>true, "Value"=>"john", "Key"=>"hello", "ResourceType"=>"auto-scaling-group"}, {"ResourceId"=>"rred", "PropagateAtLaunch"=>true, "Value"=>"test", "Key"=>"this", "ResourceType"=>"auto-scaling-group"}, {"ResourceId"=>"rred", "PropagateAtLaunch"=>true, "Value"=>"thshs", "Key"=>"thist", "ResourceType"=>"auto-scaling-group"}])
#       tags_hash = Services::Network::AutoScaling::AWS.get_tags(aws_mock_object)
#       expected_response = {"hello"=>"john", "this"=>"test", "thist"=>"thshs"}
#       expect(tags_hash).to eq(expected_response)
#     end
#   end
# 
#   context "#find_or_create_interface_connections" do
# =begin
#   it "it should create interface connection" do
#       @asg = Service.find(@asg.id)
#       expect { @asg.find_or_create_interface_connections }.to change(@asg.interfaces, :count).by(1)
#     end
# 
#     it "it should not create interface connection without launch_config" do
#       @asg = FactoryBot.create(:service, :auto_scaling, :running, vpc: @vpc)
#       @asg = Service.find(@asg.id)
#       expect { @asg.find_or_create_interface_connections }.to change(@asg.interfaces, :count).by(0)
#     end
# 
#     it "it should create interface connection with launch_config" do
#       @asg.find_or_create_interface_connections
#       expected_service_id = @asg.interfaces.where(interface_type:"Protocols::AutoScalingConfiguration").first.remote_interfaces.first.service_id
#       expect(expected_service_id).to eql(@launch_config.id)
#     end
# =end
#   end
# 
#   context "#reload_service" do
#     before(:all) do
#       @asg = FactoryBot.create(:service, :auto_scaling, :running, vpc: @vpc)
#       @asg.provider_data = {"instances" => []}
#       @asg.provider_data_will_change!
#       @asg.save!
#       @asg = Service.find(@asg.id)
#       @response = [
#         {'InstanceId' => 'id1'},
#         {'InstanceId' => 'id2'}
#       ]
#     end
# 
#     before(:each) do
#       allow(@asg).to receive(:aws_autoscaling_agent).and_return([])
#       allow_any_instance_of(ProviderWrappers::AWS::Networks::AutoScaling).to receive(:fetch_instances).and_return(@response)
#     end
# 
#     # it "return true when updated instance of auto_scaling" do
#     #   expect(@asg.reload_service).to eq true
#     # end
# 
#     it "should return the instance ids of response" do
#       expect(@asg.get_instance_ids(@response)).to eq(%w(id1 id2))
#     end
# 
#     it "should change the attribute provider_data of autoscaling object" do
#       expect { @asg.update_instance_ids(%w('value1' 'value2')) }.to change(@asg, :data)
#     end
# 
#     it "should return updated instance ids to the object" do
#       @ids = %w(someid1 someid2)
#       @asg.update_instance_ids(@ids)
#       expect(@asg.instance_ids).to eq(@ids)
#     end
#   end
# 
#   describe "#update_service_via_sidekiq" do
#     context "when provider_id is nil" do
#       it "should return nil if service does not have provider id" do
#         expect(@asg.update_service_via_sidekiq({})).to eq nil
#       end
#     end
# 
#     context "when provider_id is not nil" do
#       before(:each) do
#         allow_any_instance_of(ProviderWrappers::AWS::Networks::AutoScaling).to receive(:udpate).and_return(true)
#         allow_any_instance_of(ProviderWrappers::AWS::Networks::AutoScaling).to receive(:fetch_remote_asg).and_return(@asg)
#       end
#       it "should udpate the provider data of provider_id is available" do
#         asg = Services::Network::AutoScaling::AWS.new(provider_id: 'someid')
#         allow(asg).to receive(:aws_autoscaling_agent).and_return([])
#         allow(asg).to receive(:save_instance_ids).and_return(true)
#         allow(asg).to receive(:update_local_subnets).and_return(true)
#         allow(asg).to receive(:update_local_launch_config).and_return(true)
#         expect(asg.update_service_via_sidekiq({})).to eq true
#       end
#     end
#   end
# 
#   context "#update_local_asg" do
#     it "should update the old asg" do
#       old_asg = FactoryBot.create(:service, :auto_scaling_aws, :running, vpc: @vpc, data: @data)
#       @old_asg = Service.find old_asg.id
#       updated_asg = FactoryBot.create(:service, :auto_scaling_aws, :running, vpc: @vpc, data: @updated_data)
#       @updated_asg = Service.find updated_asg.id
#       @old_asg.update_local_asg(@updated_asg)
#       expect(@old_asg.reload.data).to eq(@updated_data)
#     end
#   end
# 
#   context "#update_local_subnets" do
#     it "should return nil if subnets not provided" do
#       old_asg = FactoryBot.create(:service, :auto_scaling_aws, :running, vpc: @vpc, data: @data)
#       @old_asg = Service.find old_asg.id
#       expect(@old_asg.update_local_subnets([])).to eq(nil)
#     end
#     it "should update the old asg with the subnets" do
# 
#     end
#   end
# 
#   context "terminate the autoscaling group" do
#     before(:each) do
#       @env = FactoryBot.create(:environment, :running)
#       @server = FactoryBot.create(:service, :server, :server_aws, :running, :with_asg_server, :aws)
#       @volume = FactoryBot.create(:service, :volume, :volume_aws, :running, :aws)
#       @autoscaling = FactoryBot.create(:service, :auto_scaling, :running, vpc: @vpc)
#       @autoscaling = Service.find @autoscaling
#       @load_balancer = FactoryBot.create(:service, :load_balancer, :load_balancer_aws, :running, :aws)
#       @env.services << @server
#       @env.services << @volume
#       @env.services << @load_balancer
#       @env.services << @autoscaling
#     end
#     context "terminate_service" do
#       before(:each) do
#         allow_any_instance_of(ProviderWrappers::AWS::Networks::AutoScaling).to receive(:destroy).and_return(true)
#         allow(@autoscaling).to receive(:aws_autoscaling_agent).and_return([])
#       end
#       describe "when called terminate service" do
#         it "should return true" do
#           expect(@autoscaling.terminate_service).to eq(true)
#         end
#       end
#     end
#     context "#terminate_created_servers" do
#       describe "server state should be terminated" do
#         it "should terminate the server when its asg created server" do
#           server = FactoryBot.create(:service, :server, :server_aws, :terminated, :with_asg_server, :aws)
#           @autoscaling.terminate_created_servers
#           allow(@autoscaling).to receive(:fetch_child_services).and_return([server])
#           expect(@autoscaling.fetch_child_services(Services::Compute::Server::AWS).map(&:state).uniq).to eq(["terminated"])
#         end
#       end
#     end
#     context '#terminate_remaining_server_service' do
#       before(:each) do
#         asg = FactoryBot.create(:service, :auto_scaling, :running, vpc: @vpc, data:{'launch_configuration_name' => @launch_config.name})
#         @asg = Service.find asg.id
#         @remaining_server = FactoryBot.create(:service, :server, :server_aws, :running, :with_asg_server, :aws, provider_id: 'asg-1234')
#         @remaining_server2 = FactoryBot.create(:service, :server, :server_aws, :running, :with_asg_server, :aws, provider_id: 'asg-12345')
#         @remaining_server = Service.find @remaining_server
#         @remaining_server2 = Service.find @remaining_server2
#         @env.services << @remaining_server
#         @env.services << @remaining_server2
#         allow(@autoscaling).to receive(:fetch_child_services).and_return([@remaining_server, @remaining_server2])
#       end
#       describe "terminate only autoscaling server" do
#         it 'should change the state of asg server to terminated' do
#           @autoscaling.terminate_remaining_server_service(['some_id'])
#           expect(@remaining_server.reload.state).to eq("terminated")
#         end
#         it 'should not change the state of normal server' do
#           @autoscaling.terminate_remaining_server_service(['some_id'])
#           expect(@server.reload.state).to eq("running")
#         end
#       end
#     end
#   end
# 
#   describe '#format_attributes_by_raw_data' do
#     @keys = [ :name, :max_size, :min_size, :policies, :desired_capacity, :default_cooldown, :health_check_type, :launch_configuration_name, :health_check_grace_period, :state, :tags]
#     @aws_service = FactoryBot.build(:fog_autoscaling)
#     it_behaves_like "aws_attribute_formater", @aws_service, @keys
#   end
# 
#   context "#get_policy_arn" do
#     before(:each) do
#       @asg = Service.find(@asg.id)
#       @asg.policies =  [
#         {
#           "id" => "autoscalinggroup00012_policy_0",
#           "alarm" => "autoscalinggroup00012_policy_0_alarm",
#           "action" => "add",
#           "scaling_adjustment" => 1,
#           "adjustment_type" => "ChangeInCapacity",
#           "cooldown" => 300
#         }
#       ]
#       @asg.policies_name_to_arn_map = {
#         "autoscalinggroup00012_policy_0"=>"{\"id\":\"autoscalinggroup00012_policy_0\",\"adjustment_type\":\"ChangeInCapacity\",\"scaling_adjustment\":1,\"cooldown\":300,\"auto_scaling_group_name\":\"autoscalinggroup00012\",\"alarms\":[],\"arn\":\"arn:aws:autoscaling:us-west-1:707082674943:scalingPolicy:dce2560d-04c8-45c6-ba37-aa7bfd8e0d0e:autoScalingGroupName/autoscalinggroup00012:policyName/autoscalinggroup00012_policy_0\"}"
#       }
#       @asg.data_will_change!
#       @asg.save!
#     end
#     describe "when policy array is provided" do
#       it "should return the arn of the policy" do
#         res = ["arn:aws:autoscaling:us-west-1:707082674943:scalingPolicy:dce2560d-04c8-45c6-ba37-aa7bfd8e0d0e:autoScalingGroupName/autoscalinggroup00012:policyName/autoscalinggroup00012_policy_0"]
#         expect(@asg.get_policy_arn(["autoscalinggroup00012_policy_0"])).to eq(res)
#       end
#       it "should retutn empty array if arn is not provided" do
#         expect(@asg.get_policy_arn([])).to eq([])
#       end
#     end
#     describe "when creating a policy" do
#       it "should return the udpated policy" do
#         res_hash = {
#           id: "autoscalinggroup00012_policy_0",
#           arn: "some_arn",
#           adjustment_type: "ChangeInCapacity",
#           alarms: [],
#           auto_scaling_group_name: "autoscalinggroup00012",
#           cooldown: 300,
#           min_adjustment_step: nil,
#           scaling_adjustment: 1
#         }
#         asg_remote_object = OpenStruct.new(res_hash)
#         @asg = Service.find(@asg.id)
#         dummy_agent = OpenStruct.new
#         allow(@asg).to receive(:wrapper_agent).and_return(dummy_agent)
#         allow(dummy_agent).to receive(:put_policy).and_return(asg_remote_object)
#         expect(@asg.send(:create_policies)).to eq(@asg.reload.policies)
#       end
#     end
#   end
# end
