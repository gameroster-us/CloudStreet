# require 'spec_helper'

# describe SubscriptionFetcher do

# 	before(:each) do
# 		allow_any_instance_of(Adapters::Azure).to receive(:update_subscriptions).and_return(true)
#     @adapter = FactoryBot.create(:adapter_azure)
#     @subscription = FactoryBot.create(:subscription_azure)
#     @adapter.subscriptions << @subscription
#     @adapter.save!
#   end

#   describe "#fetch_all_subscriptions" do
#     it 'fetches all the adapter subscriptions' do
#       expect(SubscriptionFetcher.fetch_all_subscriptions(@adapter).count).to eq(1)
#     end

#     it 'fetches 0 subscriptions if no subscriptions present' do
#       adapter = FactoryBot.create(:adapter_azure)
#       expect(SubscriptionFetcher.fetch_all_subscriptions(adapter).count).to eq(0)
#     end
#   end

# end
