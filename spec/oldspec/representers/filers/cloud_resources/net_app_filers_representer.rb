# require 'spec_helper'
# module Filers
#   module CloudResources
#     describe Filers::CloudResources::NetAppFilersRepresenter do
#       before(:all) do
#         @account ||= FactoryBot.create(:account, :with_user)
#         @cloud_res_adapter = FactoryBot.create(:cloud_resource_adapter, account: @account)
#         @net_app_filers = FactoryBot.create(:filer, account: @account, cloud_resource_adapter: @cloud_resource_adapter)
#         @net_app_filers.extend(Filers::CloudResources::NetAppFilersRepresenter)
#         @represented_hash = @net_app_filers.attributes
#       end

#       describe 'represented hash' do
#         it { expect(@represented_hash['id']).to eq(@net_app_filers.id) }
#         it { expect(@represented_hash['name']).to eq(@net_app_filers.name) }
#         it { expect(@represented_hash['public_id']).to eq(@net_app_filers.public_id) }
#         it { expect(@represented_hash['data']).to eq(@net_app_filers.data) }
#         it { expect(@represented_hash['account_id']).to eq(@net_app_filers.account_id) }
#         it { expect(@represented_hash['cloud_resource_adapter_id']).to eq(@net_app_filers.cloud_resource_adapter_id) }
#         it { expect(@represented_hash['filer_configurations']).to eq(nil) }
#         it { expect(@represented_hash['filer_volumes']).to eq(nil) }
#         it { expect(@represented_hash['enabled']).to eq(true) }
#       end
#     end
#   end
# end
