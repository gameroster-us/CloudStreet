# require 'spec_helper'
# 
# describe Services::Compute::Server do
#   describe "#create_service_interfaces" do
#     before(:all) do
#       @user = FactoryBot.create(:user_iam_role)
#       @env = FactoryBot.create(:environment, account_id: @user.account_id, revision: 1.0)
# 
#       @vpc = FactoryBot.create(:service, :vpc, :running, account_id: @user.account_id)
#       @vpc = Service.find(@vpc.id)
#       @env.services << @vpc
# 
#       @subnet = FactoryBot.create(:service, :subnet, :running, account_id: @user.account_id)
#       @subnet = Service.find(@subnet.id)
#       @env.services << @subnet
# 
#       @security_group = FactoryBot.create(:service, :security_group, :running, name: 'default', account_id: @user.account_id)
#       @security_group = Service.find(@security_group.id)
#       @env.services << @security_group
# 
#       @server = FactoryBot.create(:service, :running, :server)
#       @server = Service.find(@server.id)
#       @env.services << @server
#     end
# 
#     it "should not create interface for {} params" do
#       expect { @server.create_service_interfaces({}) }.to change(@server.reload.interfaces, :count).by(0)
#     end
# 
#     it "should create only two interfaces for valid params" do
#       params = { subnet_id: @subnet.id, vpc_id: @vpc.id }
#       expect { @server.create_service_interfaces(params) }.to change(@server.reload.interfaces, :count).by(2)
#     end
#   end
# end
