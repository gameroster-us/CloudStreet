# require 'spec_helper'

# describe Network::SecurityGroupCreator do
#   before(:all) do
#     @user = FactoryBot.create(:user_iam_role)
#     @adapter = FactoryBot.create(:adapter, :aws, account_id: @user.account_id)
#     @user.account.create_general_setting(ip_auto_increment_enabled: true, naming_convention_enabled: false)
#     @vpc = FactoryBot.create(:service, :vpc, provider_id: 'sg_vpc_id', data: {"vpc_id" => 'sg_vpc_id'})
#     @vpc_aws = FactoryBot.create(:aws_vpc, vpc_id: 'sg_vpc_id')
#     @vpc.find_or_create_default_interface_connections
#     @region = FactoryBot.create(:region, :aws_adapter)
#     @env = FactoryBot.create(:environment, account_id: @user.account_id, revision: 1.0, default_adapter_id: @adapter.id, region_id: @region.id)
#     @env.services << @vpc
#     FactoryBot.create(:service, :security_group_aws, :directory)
#   end

#   describe "#create" do
# 	  it 'should create SecurityGroup' do
# 	    @params = OpenStruct.new(
# 	      environment_id: @env.id,
# 	      group_name: "Group Name",
# 	      description: "Security Group description",
# 	      vpc_id: @vpc.id,
# 	      type: 'Services::Network::SecurityGroup::AWS')

#         allow_any_instance_of(Validators::Services::Network::AutoScaling::AWS).to receive(:vpc_service).and_return(@vpc)

# 	    expect { Network::SecurityGroupCreator.create(@params, @user) }.to change(Services::Network::SecurityGroup::AWS, :count).by(0)
# 	  end
#    end

# end
