# require 'spec_helper'
# 
# describe AWSRecords::Network::ElasticIp::AWS do
#   it_behaves_like "provider_data_store_constants", AWSRecords::Network::ElasticIp::AWS, "Services::Network::ElasticIP::AWS", false
# 
#   it_behaves_like "provider_data_store" do
#     before(:all){
#       keys = {
#         account_id: SecureRandom.hex,
#         adapter_id: SecureRandom.hex,
#         region_id: SecureRandom.hex
#       }
#       @service = FactoryBot.build(:ds_eip, :with_data_id, :with_data_server, keys)
#       ds_nic = FactoryBot.create(:ds_nic, :with_data_vpc_id, keys.merge(provider_id: @service.data["network_interface_id"]))
#       ds_nic.provider_vpc_id = ds_nic.data["vpc_id"]
#       ds_nic.save!
#       @service.provider_vpc_id = ds_nic.provider_vpc_id
# 
#       @provider_id = @service.data["public_ip"]
#       @provider_vpc_id = ds_nic.provider_vpc_id
#     }
# 
#     describe "#creating?" do
#       it "should return false" do
#         expect(@service.creating?).to eq(false)
#       end
#     end
#   end
# end
