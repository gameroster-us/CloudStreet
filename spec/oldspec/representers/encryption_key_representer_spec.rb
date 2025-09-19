# require 'spec_helper'

# describe EncryptionKeyRepresenter do
#   before(:all) do
#     @account ||= FactoryBot.create(:account, :with_user)
#     @adapter ||= FactoryBot.create(:adapter,:aws, account_id: @account.id)
#     @region ||= FactoryBot.create(:region, code: 'eu-central-1')
#     @encryption_key = FactoryBot.create(:encryption_key, adapter_id: @adapter.id, region_id: @region.id, account_id: @account.id)
#     @encryption_key.extend(EncryptionKeyRepresenter)
#     json = @encryption_key.to_json
#     @represented_hash = JSON.parse(json)
#   end

#   describe 'represented hash' do
#     it { expect(@represented_hash['key_id']).to eq(@encryption_key.key_id) }
#     it { expect(@represented_hash['key_alias']).to eq(@encryption_key.key_alias) }
#     it { expect(@represented_hash['creation_date']).to eq(@encryption_key.creation_date.strftime CommonConstants::DEFAULT_TIME_FORMATE ) }
#     it { expect(@represented_hash['arn']).to eq(@encryption_key.arn) }
#     it { expect(@represented_hash['enabled']).to eq(@encryption_key.enabled) }
#     it { expect(@represented_hash['state']).to eq(@encryption_key.state) }
#     it { expect(@represented_hash['account_id']).to eq(@encryption_key.account_id) }
#   end
# end
