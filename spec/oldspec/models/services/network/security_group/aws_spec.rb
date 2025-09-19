# require 'spec_helper'
# 
# describe Services::Network::SecurityGroup::AWS do
#   describe '#get_attributes' do
#     it 'should return attributes for object' do
#       security_group = FactoryBot.create(:service, :security_group)
#       security_group = Service.find(security_group.id)
#       expect(security_group.get_attributes).to include(security_group.attributes)
#     end
#   end
# 
#   describe '#format_attributes_by_raw_data' do
#     @keys = [:name, :description, :group_id, :ip_permissions, :ip_permissions_egress, :owner_id, :tags]
# 
#     @aws_service = FactoryBot.build(:fog_security_group)
# 
#     it_behaves_like "aws_attribute_formater", @aws_service, @keys
#   end
# 
#   describe '#validate_for_termination' do
#     it "should not delete default Security group" do
#       security_group = FactoryBot.create(:service, :security_group, data: { 'default' =>  true})
#       security_group = Service.find(security_group.id)
#       allow(security_group).to receive(:get_referenced_sgs).and_return([])
#       security_group.send(:validate_for_termination)
#       expect(security_group.errors.messages).to include(:dependent_service)
#     end
# 
#     context 'if attached to Server' do
#       before(:each) do
#         @security_group = FactoryBot.create(:service, :security_group_aws)
#         @security_group = Service.find(@security_group.id)
#         allow(@security_group).to receive(:fetch_child_services).with(Services::Database::Rds::AWS).and_return([])
#         allow(@security_group).to receive(:fetch_child_services).with(Services::Network::LoadBalancer::AWS).and_return([])
#         allow(@security_group).to receive(:fetch_child_services).with(Services::Network::AutoScalingConfiguration::AWS).and_return([])
#         allow(@security_group).to receive(:get_referenced_sgs).and_return([])
#       end
# 
#       it "should delete Security group if server is terminated" do
#         server = FactoryBot.create(:service, :server_aws, :terminated)
#         server = Service.where(id: server.id)
#         allow(@security_group).to receive(:fetch_child_services).with(Services::Compute::Server::AWS).and_return(server)
# 
#         @security_group.send(:validate_for_termination)
#         expect(@security_group.errors.messages).to be_empty
#       end
# 
#       it "should not delete Security group" do
#         server = FactoryBot.create(:service, :server_aws)
#         server = Service.where(id: server.id)
#         allow(@security_group).to receive(:fetch_child_services).with(Services::Compute::Server::AWS).and_return(server)
# 
#         @security_group.send(:validate_for_termination)
#         expect(@security_group.errors.messages).to include(:dependent_service)
#       end
#     end
# 
#     context 'if attached to LoadBalancer' do
#       before(:each) do
#         @security_group = FactoryBot.create(:service, :security_group_aws)
#         @security_group = Service.find(@security_group.id)
#         allow(@security_group).to receive(:fetch_child_services).with(Services::Compute::Server::AWS).and_return([])
#         allow(@security_group).to receive(:fetch_child_services).with(Services::Database::Rds::AWS).and_return([])
#         allow(@security_group).to receive(:fetch_child_services).with(Services::Network::AutoScalingConfiguration::AWS).and_return([])
#         allow(@security_group).to receive(:get_referenced_sgs).and_return([])
#       end
# 
#       it "should delete Security group if loadbalancer is terminated" do
#         lb = FactoryBot.create(:service, :load_balancer_aws, :terminated)
#         lb = Service.where(id: lb.id)
#         allow(@security_group).to receive(:fetch_child_services).with(Services::Network::LoadBalancer::AWS).and_return(lb)
# 
#         @security_group.send(:validate_for_termination)
#         expect(@security_group.errors.messages).to be_empty
#       end
# 
#       it "should not delete Security group" do
#         lb = FactoryBot.create(:service, :load_balancer_aws)
#         lb = Service.where(id: lb.id)
#         allow(@security_group).to receive(:fetch_child_services).with(Services::Network::LoadBalancer::AWS).and_return(lb)
# 
#         @security_group.send(:validate_for_termination)
#         expect(@security_group.errors.messages).to include(:dependent_service)
#       end
#     end
# 
#     context 'if attached to LaunchConfig' do
#       before(:each) do
#         @security_group = FactoryBot.create(:service, :security_group_aws)
#         @security_group = Service.find(@security_group.id)
#         allow(@security_group).to receive(:fetch_child_services).with(Services::Compute::Server::AWS).and_return([])
#         allow(@security_group).to receive(:fetch_child_services).with(Services::Database::Rds::AWS).and_return([])
#         allow(@security_group).to receive(:fetch_child_services).with(Services::Network::LoadBalancer::AWS).and_return([])
#         allow(@security_group).to receive(:get_referenced_sgs).and_return([])
#       end
# 
#       it "should delete Security group if launchconfig is terminated" do
#         lc = FactoryBot.create(:service, :auto_scaling_configuration_aws, :terminated)
#         lc = Service.where(id: lc.id)
#         allow(@security_group).to receive(:fetch_child_services).with(Services::Network::AutoScalingConfiguration::AWS).and_return(lc)
# 
#         @security_group.send(:validate_for_termination)
#         expect(@security_group.errors.messages).to be_empty
#       end
# 
#       it "should not delete Security group" do
#         lc = FactoryBot.create(:service, :auto_scaling_configuration_aws)
#         lc = Service.where(id: lc.id)
#         allow(@security_group).to receive(:fetch_child_services).with(Services::Network::AutoScalingConfiguration::AWS).and_return(lc)
# 
#         @security_group.send(:validate_for_termination)
#         expect(@security_group.errors.messages).to include(:dependent_service)
#       end
#     end
# 
#     context 'if attached to RDS' do
#       before(:each) do
#         @security_group = FactoryBot.create(:service, :security_group_aws)
#         @security_group = Service.find(@security_group.id)
#         allow(@security_group).to receive(:fetch_child_services).with(Services::Compute::Server::AWS).and_return([])
#         allow(@security_group).to receive(:fetch_child_services).with(Services::Network::AutoScalingConfiguration::AWS).and_return([])
#         allow(@security_group).to receive(:fetch_child_services).with(Services::Network::LoadBalancer::AWS).and_return([])
#         allow(@security_group).to receive(:get_referenced_sgs).and_return([])
#       end
# 
#       it "should delete Security group if RDS is terminated" do
#         rds = FactoryBot.create(:service, :rds_aws, :terminated)
#         rds = Service.where(id: rds.id)
#         allow(@security_group).to receive(:fetch_child_services).with(Services::Database::Rds::AWS).and_return(rds)
# 
#         @security_group.send(:validate_for_termination)
#         expect(@security_group.errors.messages).to be_empty
#       end
# 
#       it "should not delete Security group" do
#         rds = FactoryBot.create(:service, :rds_aws)
#         rds = Service.where(id: rds.id)
#         allow(@security_group).to receive(:fetch_child_services).with(Services::Database::Rds::AWS).and_return(rds)
# 
#         @security_group.send(:validate_for_termination)
#         expect(@security_group.errors.messages).to include(:dependent_service)
#       end
#     end
#   end
# end
