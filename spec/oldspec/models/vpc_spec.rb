# require 'spec_helper'
# 
# describe Vpc do
#   describe "validations" do
#     it { should validate_presence_of(:adapter) }
#     it { should validate_presence_of(:name) }
#     it { should validate_presence_of(:cidr) }
#     it { should validate_presence_of(:user_role_ids) }
#   end
#   before(:all) do
#     @account = FactoryBot.create(:account)
#     @adapter = FactoryBot.create(:adapter_aws)
#     @vpc = FactoryBot.create(:vpc, account_id: @adapter.account_id, adapter_id: @adapter.id)
#   end
# 
#   describe "to update vpc access" do
#   end
#   it "it should invalid if account is nil" do
#     updated = @vpc.assign_accessible_roles(nil, [])
#     expect(updated).to eql(false)
#   end
# 
#   it "it should invalid if user_role_id is nil" do
#     updated = @vpc.assign_accessible_roles(@account, nil)
#     expect(updated).to eql(false)
#   end
# 
#   it "it should valid if valid fields" do
#     updated = @vpc.assign_accessible_roles(@account, ['0c410398-6e59-4b8c-ac07-86ee59ecb6c9'])
#     expect(updated).to eql(false)
#   end
# 
#   describe "#can_sync?" do
#     before(:all) do
#       @current_vpc = @vpc.dup
#     end
# 
#     it "should return true if vpc is created before with the same adapter" do
#       expect(@current_vpc.can_sync?).to be true
#     end
# 
#     it "should return true if vpc is not yet created in cloudstreet" do
#       @current_vpc = @vpc.dup
#       expect(@current_vpc.can_sync?).to be true
#     end
# 
#     it "should return false if vpc has been created with another adapter" do
#       @current_vpc = @vpc.dup
#       @current_vpc.adapter_id = SecureRandom.hex
#       expect(@current_vpc.can_sync?).to be false
#     end
#   end
# end
