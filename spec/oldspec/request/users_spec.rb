# require "spec_helper"

# describe "Users:" do
#   describe "disable intro" do
#     context "when logged in" do
#       before(:all) do
#         @user = FactoryBot.create(:user)
#         @env  = http_login(@user)
#         put disable_intro_user_path(id: @user.id), {}, @env
#       end

#       it "responds with 204" do
#         expect(response).to have_http_status(204)
#       end
#     end
#   end

#   describe "update user preference" do
#     context "when logged in" do
#       before(:all) do
#         @user = FactoryBot.create(:user)
#         @env  = http_login(@user)
#         put change_user_preference_users_path, {"preferences" => {"sync_guidelines" => "true"}, "type" => "User"}, @env
#       end

#       it "responds with 204" do
#         expect(response).to have_http_status(204)
#       end
#     end
#   end

# #   describe "list users" do

# #     context "when logged in" do
# #       before(:all) do
# #         get users_path, {}, @env
# #       end

# #       it "responds with 200" do
# #         expect(response).to be_success
# #       end

# #       describe "links" do
# #         it "contains a link to self" do
# #           expect(json["_links"]["self"]["href"]).to eq "/users"
# #         end
# #       end
# #     end

# #     # pending "when not logged in" do
# #     #   it "returns a 401"
# #     # end
# #   end

# #   describe "show a user" do
# #     context "when resource exists" do
# #       before(:all) do
# #         get user_path(id: @user.id), {}, @env
# #       end

# #       it "responds with 200" do
# #         expect(response).to be_success
# #       end

# #       it "returns the user" do
# #         expect(json["id"]).to eq @user.id
# #       end

# #       describe "links" do
# #         it "contains a link to self" do
# #           expect(json["_links"]["self"]["href"]).to eq user_path(id: @user.id)
# #         end
# #       end
# #     end

# #     # context "when resource is not found" do
# #     #   it "responds with 404"
# #     # end

# #     # context "when resource is not owned" do
# #     #   context "when resource belongs to a users account" do
# #     #     it "responds with 403"
# #     #   end
# #     #   context "when resource does not belong to a users account" do
# #     #     it "responds with 404"
# #     #   end
# #     # end
# #   end
# end
