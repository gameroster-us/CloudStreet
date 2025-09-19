# require "spec_helper"

# describe TemplateSearcher do
#   before(:all) do
#     @user1 = FactoryBot.create(:user_iam_role)
#     @user2 = FactoryBot.create(:user_iam_role)
#     @user_account = @user1.account
#     @other_account = @user2.account
#     @region1 = FactoryBot.create(:region, :aws_adapter)
#     @region2 = FactoryBot.create(:region, :rackspace_adapter)
#     @template1 = FactoryBot.create(:template, account: @user_account, region: @region1, adapter: @region1.adapter)
#     @template2 = FactoryBot.create(:template, account: @other_account, region: @region2, adapter: @region2.adapter)
#   end
#   context ".search" do
#     context "when account is specified" do
#       before(:all) do
#         FactoryBot.create(:template, account: @user_account, region: @region1, adapter: @region1.adapter)
#         @size = 16
#         @number = 1
#         @page_params = { page_size: @size, page_number: @number }
#         @search_params = {}
#         @templates = TemplateSearcher.search(@user_account, @user1, @page_params, @search_params) {}
#       end

#       it "returns the result of ActiveRecord::Relation object" do
#         expect(@templates).to be_a(ActiveRecord::Relation)
#       end

#       it "returns the number of found templates" do
#         expect(@templates.count).to eq 2
#       end

#       it "does not have templates of other account" do
#         uniq_account = @templates.map(&:account_id).uniq
#         expect(uniq_account).to eq [@user_account.id]
#       end
#     end

#     context "when page params are specified" do
#       let(:page_params) { {page_size: @size, page_number: @number} }
#       let(:search_params) { {} }
#       let(:templates) { TemplateSearcher.search(@user_account, @user1, page_params, search_params) {} }
#       it "should return only one template when page size is 1 and page number 1" do
#         @size = 1
#         @number = 1
#         expect(templates.count).to eq 1
#       end

#       it "should return only one template when page size is 1 and page number 2" do
#         @size = 1
#         @number = 2
#         FactoryBot.create(:template, account: @user_account, region: @region1, adapter: @region1.adapter)
#         expect(templates.count).to eq 1
#       end
#     end

#     context "when search params are provided" do
#       before(:all) do
#         @size = 16
#         @number = 1
#         @page_params = {page_size: @size, page_number: @number}
#       end
#       let(:search_params) { {region_id: @region_id, adapter_id: @adapter_id, state: @state, to_date: @to_date, from_date: @from_date} }
#       let(:templates) { TemplateSearcher.search(@user_account, @user1, @page_params, search_params) {} }

#       context "if the region is specified" do
#         it "should return the templates of the region specified" do
#           @region_id = @region1.id
#           expect(templates.pluck(:region_id).uniq).to eq [@region_id]
#         end

#         it "should not include the templates of other region" do
#           region_id = @region2.id
#           search_params = {region_id: region_id}
#           result = TemplateSearcher.search(@user_account, @user1, @page_params, search_params) {}
#           expect(result.pluck(:region_id).uniq).not_to eq [@region1.id ]
#         end
#       end

#       context "if the adapter is specified" do
#         it "should return the template of the same adapter id specified" do
#           @adapter_id = @region1.adapter_id
#           expect(templates.pluck(:adapter_id).uniq).to eq [@adapter_id]
#         end
#       end

#       context "if the state is specified" do
#         it "should return the template of the state specified" do
#           @state = "pending"
#           uniq_state = templates.pluck(:state).uniq
#           expect(uniq_state).to eq ["pending"]
#         end
#       end

#       context "if the date range is specified" do
#         it "should match template id returned between the dates specified" do
#           other_date_template = FactoryBot.create(:template, account: @user_account, region: @region1, adapter: @region1.adapter)
#           other_date_template.updated_at = Date.today-7.days
#           other_date_template.save
#           @to_date = Date.today.strftime("%Y-%m-%d")
#           @from_date = (Date.today-1.day).strftime("%Y-%m-%d")

#           expect(templates.pluck(:id)).not_to include(other_date_template.id)
#         end
#       end
#     end
#   end
# end
