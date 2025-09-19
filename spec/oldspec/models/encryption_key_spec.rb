# require 'spec_helper'
# 
# describe EncryptionKey do
# 
#   it { should belong_to(:account) }
#   it { should belong_to(:adapter) }
#   it { should belong_to(:region) }
# 
# 	describe "#find_or_create_key" do
# 		before(:all) do
# 			@account ||= FactoryBot.create(:account, :with_user)
#       @adapter ||= FactoryBot.create(:adapter,:aws, account_id: @account.id)
#       @region ||= FactoryBot.create(:region, code: 'eu-central-1')
#       @encryption_key = FactoryBot.create(:encryption_key, adapter_id: @adapter.id, region_id: @region.id, account_id: @account.id)
# 		end
# 
#   	it 'should not create encryption key' do
#    		key_info = { 'key_id' => "MyString", 'account_id' => @account.id,
#    								 'adapter_id' => @adapter.id, 'region_id' => @region.id }
#   		expect { EncryptionKey.find_or_create_key(key_info) }.not_to change{ EncryptionKey.count }
#  		end
# 
#  		it 'should create encryption key with different account_id ' do
#  			account ||= FactoryBot.create(:account, :with_user)
#    		key_info = { 'key_id' => "MyString", 'account_id' => account.id,
#    								 'adapter_id' => @adapter.id, 'region_id' => @region.id }
#   		expect { EncryptionKey.find_or_create_key(key_info) }.to change{ EncryptionKey.count }.by(1)
#  		end
# 
#  		it 'should create encryption key with different region ' do
#  			region ||= FactoryBot.create(:region, code: 'eu-west-1')
#    		key_info = { 'key_id' => "MyString", 'account_id' => @account.id,
#    								 'adapter_id' => @adapter.id, 'region_id' => region.id }
#   		expect { EncryptionKey.find_or_create_key(key_info) }.to change{ EncryptionKey.count }.by(1)
#  		end
# 
#  		it 'should create encryption key with unique key_id ' do
#    		key_info = { 'key_id' => "MyString1", 'account_id' => @account.id,
#    								 'adapter_id' => @adapter.id, 'region_id' => @region.id }
#   		expect { EncryptionKey.find_or_create_key(key_info) }.to change{ EncryptionKey.count }.by(1)
#  		end
# 
#   end
# end
