# require "spec_helper"

# describe "adapters." do
#   before(:all) do
#     @owner ||= FactoryBot.create(:user)
#     @owner_env  ||= http_login(@owner)

#     @user ||= FactoryBot.create(:user)
#     @user_env ||= http_login(@user)

#     @member ||= FactoryBot.create(:user)
#     group = @owner.account.groups.where(name: "members").first_or_create!
#     group.add_user(@member)
#     @member_env ||= http_login(@member)

#     @adapter     ||= FactoryBot.create(:adapter, :aws)
#     @adapter_aws ||= FactoryBot.create(:adapter, :aws)
#     @owner.accounts.first.adapters << @adapter
#     @owner.accounts.first.adapters << @adapter_aws
#   end

#   describe "list users adapters" do

    # context "when logged in as owner" do
    #   before(:all) do
    #     get adapters_path, {}, @owner_env
    #   end

    #   it "responds with 200" do
    #     expect(response).to be_success
    #   end

    #   # TODO: if run as part of the file we get 4 returned, need to figure out if we just test for > 1 or even bother
    #   # it "returns multiple adapters" do
    #   #   expect(json["_embedded"]["adapter"].length).to eq(2)
    #   # end

    #   describe "links" do
    #     it "contains a link to self" do
    #       expect(json["_links"]["self"]["href"]).to eq "/adapters"
    #     end

    #     it "contains a link to the adapter directory" do
    #       expect(json["_links"]["directory"]["href"]).to eq "/adapters/directory{?type}"
    #     end

    #     # TODO: test we can create here, figure out how to change the account id
    #   end
    # end

    # TODO: we need to be able to change 'current account' to test this
    # pending "when logged in as member" do
    #   before(:all) do
    #     get adapters_path, {}, @member_env
    #   end

    #   it "responds with 200" do
    #     expect(response).to be_success
    #   end

    #   it "returns multiple adapters" do
    #     expect(json["_embedded"]["adapter"].length).to eq(2)
    #   end

    #   describe "links" do
    #     it "contains a link to self" do
    #       expect(json["_links"]["self"]["href"]).to eq "/adapters"
    #     end

    #     it "contains a link to the adapter directory" do
    #       expect(json["_links"]["directory"]["href"]).to eq "/adapters/directory{?type}"
    #     end
    #   end
    # end

    # # TODO: need to figure out current account ... can this even happen?
    # pending "when logged in with no access" do
    #   before(:all) do
    #     get adapters_path, {}, @user_env
    #   end

    #   it "responds with 403" do
    #     expect(response).to be_success
    #   end
    # end
  # end

  # describe "list adapters by type" do
  #   before(:all) do
  #     get adapters_path, { types: "Adapters::AWS" }, @owner_env
  #   end

  #   it "responds with 200" do
  #     expect(response).to be_success
  #   end

  #   it "returns an adapter matching the type" do
  #     adapter = json["_embedded"]["adapter"].detect{ |a| a["id"] == @adapter_aws.id }
  #     expect(adapter["id"]).to eq @adapter_aws.id
  #   end

  #   it "returns no adapters not matching the type" do
  #     adapter = json["_embedded"]["adapter"].detect{ |a| a["type"] != "Adapters::AWS" }
  #     expect(adapter).to be_nil
  #   end

  #   describe "links" do
  #     it "contains a link to self" do
  #       expect(json["_links"]["self"]["href"]).to eq "/adapters"
  #     end

  #     it "contains a link to the adapter directory" do
  #       expect(json["_links"]["directory"]["href"]).to eq "/adapters/directory{?type}"
  #     end
  #   end
  # end

  # describe "get an adapter" do
  #   context "as owner" do
  #     before(:all) do
  #       get adapter_path(id: @adapter.id), {}, @owner_env
  #     end

  #     it "responds with 200" do
  #       expect(response).to be_success
  #     end

  #     it "returns the adapter" do
  #       expect(json["id"]).to eq @adapter.id
  #     end

  #     describe "links" do
  #       it "contains a link to self" do
  #         expect(json["_links"]["self"]["href"]).to eq adapter_path(id: @adapter.id)
  #       end

  #       it "contains a link to remove" do
  #         expect(json["_links"]["remove"]["href"]).to eq adapter_path(id: @adapter.id)
  #       end

  #       it "contains a link to edit" do
  #         expect(json["_links"]["edit"]["href"]).to eq adapter_path(id: @adapter.id)
  #       end
  #     end
  #   end

  #   context "as member" do
  #     before(:all) do
  #       get adapter_path(id: @adapter.id), {}, @member_env
  #     end

  #     it "responds with 200" do
  #       expect(response).to be_success
  #     end

  #     it "returns the adapter" do
  #       expect(json["id"]).to eq @adapter.id
  #     end

  #     describe "links" do
  #       it "only contains one link" do
  #         expect(json["_links"].length).to eq(1)
  #       end

  #       it "contains a link to self" do
  #         expect(json["_links"]["self"]["href"]).to eq adapter_path(id: @adapter.id)
  #       end
  #     end
  #   end

  #   context "with no access" do
  #     before(:all) do
  #       get adapter_path(id: @adapter.id), {}, @user_env
  #     end

  #     it "responds with 403" do
  #       expect(response.status).to eq(403)
  #     end
  #   end
  # end

  # TODO: can they create in their current account
  # describe "create a new adapter" do
  #   context "with valid parameters" do
  #     context "when azure adapter type" do
  #       before(:all) do
  #         @adapter = {
  #           name: "herp",
  #           type: "Adapters::Azure",
  #           account_id: @owner.account.id }
  #         FactoryBot.create :adapter, :directory, :azure
  #         post adapters_path, @adapter, @owner_env
  #       end

  #       it "responds with 200" do
  #         expect(response).to be_success
  #       end
  #     end
  #   end
  # end

  # describe "delete an adapter" do
  #   context "when resource exists" do
  #     context "as the owner" do
  #       before(:all) do
  #         @new_adapter = FactoryBot.create(:adapter, :aws, account_id: @owner.account.id)
  #         delete adapter_path(id: @new_adapter.id), {}, @owner_env
  #       end

  #       it "responds with 200" do
  #         expect(response).to be_success
  #       end
  #     end

  #     context "as a member" do
  #       before(:all) do
  #         @new_adapter = FactoryBot.create(:adapter, :aws, account_id: @owner.account.id)
  #         delete adapter_path(id: @new_adapter.id), {}, @member_env
  #       end

  #       it "responds with 403" do
  #         expect(response.status).to eq(403)
  #       end
  #     end

  #     context "with no access" do
  #       before(:all) do
  #         @new_adapter = FactoryBot.create(:adapter, :aws, account_id: @owner.account.id)
  #         delete adapter_path(id: @new_adapter.id), {}, @user_env
  #       end

  #       it "responds with 403" do
  #         expect(response.status).to eq(403)
  #       end
  #     end
  #   end
  # end
# end
