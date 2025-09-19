# require 'spec_helper'

# describe "account_regions." do
#   before(:all) do
#     @aws_region_1 ||= FactoryBot.create(:region, :aws_adapter)
#     @aws_region_2 ||= FactoryBot.create(:region, :aws_adapter, region_name: 'Asia Pacific (Sydney) Region')
#     @unconfigured_rackspace_region ||= FactoryBot.create(:region, :rackspace_adapter)

#     @user        ||= FactoryBot.create(:user)
#     @user_env    ||= http_login(@user)
#     @aws_adapter ||= FactoryBot.create(:adapter, :aws, account_id: @user.account_id)
#   end

#   describe "list all account regions" do
#     context "when registered user" do
#       before(:all) do
#         get account_regions_path, {}, @user_env
#       end

#       it "responds with 200" do
#         expect(response).to be_success
#       end

#       it "returns all configured account regions" do
#         expect(json["_embedded"]["account_region"].length).to eq(2)
#       end

#       describe "links" do
#         it "contains a link to self" do
#           expect(json["_links"]["self"]["href"]).to eq account_regions_path
#         end
#       end
#     end

#     context "when guest user" do
#       before(:all) do
#         get account_regions_path, {}, nil
#       end

#       it "responds with 401" do
#         expect(response.status).to eq(401)
#       end
#     end
#   end
# end
