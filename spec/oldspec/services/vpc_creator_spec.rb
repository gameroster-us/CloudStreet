# require "spec_helper"

# describe VpcCreator do
#   let!(:user)    { FactoryBot.create(:user) }
#   let!(:account) { user.account }
#   let!(:region)        { FactoryBot.create(:region, :aws_adapter) }
#   let!(:adapter)       { FactoryBot.create(:adapter, :aws, account_id: account.id) }

#   context ".create" do
#     context "with valid attributes" do
#       let!(:vpc_attrs)    { FactoryBot.attributes_for(:vpc).except(:account_id).merge(region_id: region.id, adapter_id: adapter.id) }
#       let!(:return_value) { VpcCreator.create(account, user, vpc_attrs) {} }

#       it "creates the vpc creation event" do
#         events_vpc_ids = Events::Vpc::Create.pluck(:data).map { |attrs| attrs['vpc_id'] }
#         expect(events_vpc_ids).to include(return_value.id)
#       end

#       describe "returned vpc instance" do
#         it "is of class Vpc" do
#           expect(return_value).to be_a Vpc
#         end

#         it "does not have any error" do
#           expect(return_value.errors.any?).to be false
#         end

#         it "is persisted" do
#           expect(return_value.persisted?).to be true
#         end

#         it "belongs to account of current user" do
#           expect(return_value.account_id).to eq account.id
#         end
#       end
#     end

#     context "with invalid attributes" do
#       let!(:invalid_vpc_attrs) { FactoryBot.attributes_for(:invalid_vpc).except(:account_id).merge(region_id: region.id, adapter_id: adapter.id) }
#       let!(:return_value) { VpcCreator.create(account, user, invalid_vpc_attrs) {} }

#       describe "returned vpc instance" do
#         it "is of class vpc" do
#           expect(return_value).to be_a Vpc
#         end

#         it "contains validation errors" do
#           expect(return_value.errors.any?).to be true
#         end

#         it "is not persisted" do
#           expect(return_value.persisted?).to be false
#         end
#       end
#     end
#   end
# end
