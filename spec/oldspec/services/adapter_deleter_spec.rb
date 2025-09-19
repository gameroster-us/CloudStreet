# require 'spec_helper'

# describe AdapterDeleter do
#   context 'adapter deletion' do
#     before(:each) do
#       @adapter = FactoryBot.create(:adapter_aws_active)
#       @user = FactoryBot.create(:user)
#     end

#     context 'should throw validation error when vpcs are associcated' do
      # it 'should throw error when vpc associcated state is available' do
      #   vpc = FactoryBot.create(:aws_vpc)
      #   vpc.state = "available"
      #   vpc.save!
      #   @adapter.vpcs << vpc
      #   response  = AdapterDeleter.delete(@adapter, @user)
      #   expect(response).to eq('Can\'t delete as there are VPCs associated.')
      # end
      # it 'should throw error when vpc associcated state is error' do
      #   vpc = FactoryBot.create(:aws_vpc)
      #   vpc.state = "error"
      #   vpc.save!
      #   @adapter.vpcs << vpc
      #   response  = AdapterDeleter.delete(@adapter, @user)
      #   expect(response).to eq('Can\'t delete as there are VPCs associated.')
      # end
      # it 'should throw error when vpc associcated state is penging' do
      #   vpc = FactoryBot.create(:aws_vpc)
      #   @adapter.vpcs << vpc
      #   response  = AdapterDeleter.delete(@adapter, @user)
      #   expect(response).to eq('Can\'t delete as there are VPCs associated.')
      # end
#       it 'should not delete adapter when vpcs assocated state is not archived' do
#         vpc = FactoryBot.create(:aws_vpc)
#         vpc.state = "available"
#         vpc.save!
#         @adapter.vpcs << vpc
#         expect { AdapterDeleter.delete(@adapter, @user) }.to change { @adapter.class.count }.by(0)
#       end
#     end

#     context 'should successfully delete the adapter when no vpcs are associcated' do
#       it 'it should delete the adapter when no vpcs are associated' do
#         AdapterDeleter.delete(@adapter, @user)
#         expect(Adapter.exists?(@adapter.id)).to be(false)
#       end
#       it 'should delete the adapter when all the vpcs are archived' do
#         vpc = FactoryBot.create(:aws_vpc)
#         vpc.state = "archived"
#         vpc.save!
#         @adapter.vpcs << vpc
#         expect { AdapterDeleter.delete(@adapter, @user) }.to change { @adapter.class.count }.by(-1)
#       end
#     end
#   end
# end
