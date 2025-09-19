# require 'spec_helper'
# 
# describe Organisation do
# 
#   context "associations" do
#     it { should have_one(:account) }
#     it { should belong_to(:application_plan) }
#   end
# 
#   describe "#generate_invoice" do
#     before(:all) do
#       @application_plan = FactoryBot.create(:application_plan)
#       @organisation = FactoryBot.create(:organisation, :application_plan_id => @application_plan.id)
#       @account = FactoryBot.create(:account, :organisation => @organisation)
#     end
# 
#     it "should return true if invoice created" do
#       allow(CostData).to receive_message_chain(:where, :all, :keep_if, :group_by).and_return([])
#       expect(@organisation.generate_invoice).to be true
#     end
# 
#     it "should create an invoice" do
#       count = Invoice.count
#       allow(CostData).to receive_message_chain(:where, :all, :keep_if, :group_by).and_return([])
#       expect { @organisation.generate_invoice }.to change(Invoice, :count).by(1)
#     end
#   end
# 
# end
