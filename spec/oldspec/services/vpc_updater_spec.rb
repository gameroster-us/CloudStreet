# require "spec_helper"

# describe VpcUpdater do
#   context ".update_access" do
#   	context "when updating access for vpc" do
#   	  before(:each) do
#   	  	@account = FactoryBot.create(:account)
#   	  	@user = FactoryBot.create(:user_vpc, account_id:@account.id)
#         @vpc = FactoryBot.create(:vpc, account_id: @user.account_id)
#         @userrole = @user.account.roles.first
#       end

#       it 'should valid with valid user role' do
#       	update = VpcUpdater.update_vpc_access @user.account_id,{id:@vpc.id, user_role_ids:[@userrole.id]}
#         expect(update.class).to eql(Vpc)
#       end

#       it 'should valid with empty array user roles feilds' do
#         update = VpcUpdater.update_vpc_access @user.account_id,{id:@vpc.id, user_role_ids:[]}
#         expect(update.class).to eql(Vpc)
#       end

#       it 'should invalid with non-exist vpc' do
#         update = VpcUpdater.update_vpc_access @user.account_id,{id:nil, user_role_ids:[]}
#         expect(update).to eql(nil)
#       end

#       it 'should invalid for non-uuid for user roles' do
#         expect(VpcUpdater.update_vpc_access @user.account_id,{id:@vpc.id, user_role_ids:['ddad']}).to eql(nil)
#       end

#       it 'should invalid with non-exist user role id' do
#         update = VpcUpdater.update_vpc_access @user.account_id,{id:@vpc.id, user_role_ids:['af394d6e-2e3f-466e-bc1d-44181c56d986']}
#         expect(update).to eql(nil)
#       end
#     end
#   end
# end
