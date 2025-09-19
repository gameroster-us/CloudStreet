# require 'spec_helper'
# 
# describe Subscriptions::Azure do
# 	before(:each) do
# 		allow_any_instance_of(Adapters::Azure).to receive(:update_subscriptions).and_return(true)
#     @adapter = FactoryBot.create(:adapter_azure)
#     @subscription = FactoryBot.create(:subscription_azure)
#     @adapter.subscriptions << @subscription
#     @adapter.save!
#   end
# 
#   describe "#fetch_subscription" do
#   	it "fetches the subscriptions with the given provider_subscription_id " do
#   		expect(Subscriptions::Azure.fetch_subscription(@adapter, @subscription.provider_subscription_id)).to eq(@subscription)
#   	end
#   end
# 
#   describe "#create_or_update_subscription" do
#   	it "Updates local subscription if the subscription already exists" do
#   		subscription_data = {"id"=>"test_id_url", "subscription_id"=>"test_subscription", "display_name"=>"test_name", "state"=>"Enabled", "subscription_policies"=>{}}
#   		Subscriptions::Azure.create_or_update_subscription(subscription_data, @adapter)
#   		expect(@adapter.subscriptions.count).to eq(1)
#   	end
# 
#   	it "Creates a new subscription if the subscription does not exist" do
#   		subscription_data = {"id"=>"test_id_url", "subscription_id"=>"test_subscription_new", "display_name"=>"test_name", "state"=>"Enabled", "subscription_policies"=>{}}
#   		Subscriptions::Azure.create_or_update_subscription(subscription_data, @adapter)
#   		expect(@adapter.subscriptions.count).to eq(2)
#   	end
#   end
# end
