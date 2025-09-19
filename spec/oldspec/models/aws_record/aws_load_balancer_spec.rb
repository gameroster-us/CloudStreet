# require 'spec_helper'
# 
# describe AWSRecords::Network::LoadBalancer::AWS do
#   it_behaves_like "provider_data_store_constants", AWSRecords::Network::LoadBalancer::AWS, "Services::Network::LoadBalancer::AWS", false
# 
#   it_behaves_like "provider_data_store" do
#     before(:all){
#       @service = FactoryBot.build(:ds_elb, :with_data_id, :with_data_vpc_id, :unset_provider_id, :unset_provider_vpc_id)
#       @provider_id = @service.data["id"]
#       @provider_vpc_id = @service.data["vpc_id"]
#     }
# 
#     describe "#creating?" do
#       it "should return false" do
#         expect(@service.creating?).to eq(false)
#       end
#     end
#   end
# end
