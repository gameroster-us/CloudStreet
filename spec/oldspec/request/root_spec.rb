# require "spec_helper"

# describe "root." do
#   before(:all) do
#     get root_path, {}, @env
#   end

#   it "responds with 200" do
#     expect(response).to be_success
#   end

#   describe "links" do
#     it "contains a link to self" do
#       expect(json["_links"]["self"]["href"]).to eq root_path
#     end

#     it "contains a link to accounts" do
#       expect(json["_links"]["accounts"]["href"]).to eq "/accounts{/id}"
#     end

#     it "contains a link to adapters" do
#       expect(json["_links"]["adapters"]["href"]).to eq "/adapters{/id}{?types}"
#     end

#     it "contains a link to environments" do
#       expect(json["_links"]["environments"]["href"]).to eq "/environments{/id}"
#     end

#     it "contains a link to events" do
#       expect(json["_links"]["events"]["href"]).to eq "/events{/services}{?environment_id,service_id,start_date,end_date}"
#     end

#     it "contains a link to metrics" do
#       expect(json["_links"]["metrics"]["href"]).to eq "/metrics{/search}{?environment_id,service_id,metric,date_range}"
#     end

#     it "contains a link to resources" do
#       expect(json["_links"]["resources"]["href"]).to eq "/resources{/id}"
#     end

#     it "contains a link to services" do
#       expect(json["_links"]["services"]["href"]).to match(/^\/services/)
#     end

#     it "contains a link to templates" do
#       expect(json["_links"]["templates"]["href"]).to eq "/templates{/id}"
#     end

#     it "contains a link to users" do
#       expect(json["_links"]["users"]["href"]).to eq "/users{/id}"
#     end

#     it "contains a link to groups" do
#       expect(json["_links"]["groups"]["href"]).to eq "/groups{/id}"
#     end

#     it "contains a link to user" do
#       expect(json["_links"]["user"]["href"]).to eq "/user"
#     end
#   end

#   # pending "is cached for a minute"
# end
