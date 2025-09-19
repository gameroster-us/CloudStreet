# require 'spec_helper'
# 
# describe Events::Service::AddedFromProvider do
#   it { have_store_accessor(:service) }
#   it { have_store_accessor(:revision) }
#   it { have_store_accessor(:environment) }
#   it { have_store_accessor(:user) }
# 
#   describe '.create_from_service' do
#     before(:all) do
#       @environment = FactoryBot.create(:environment, :running, :with_service)
#       @account = FactoryBot.create(:account, :with_user)
#       @service = @environment.services.first
#       @user = @account.users.first
#       @service.account = @account
#     end
# 
#     it 'saves event in to database' do
#       expect { Events::Service::AddedFromProvider.create_from_service(@service, @user) }.to change { Events::Service::AddedFromProvider.count }.by(1)
#     end
#   end
# end
