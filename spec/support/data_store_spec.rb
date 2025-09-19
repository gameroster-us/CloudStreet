# shared_examples "provider_data_store_constants" do |klass, service_klass, reusable|
#   it "should have SERVICE_CLASS constant" do
#     expect(klass).to have_constant(:SERVICE_CLASS) 
#   end

#   it "should have REUSABLE constant" do
#     expect(klass).to have_constant(:REUSABLE) 
#   end

#   it "should have value of SERVICE_CLASS constant as #{service_klass}" do
#     expect(klass::SERVICE_CLASS).to eq(service_klass)
#   end

#   it "should have value of REUSABLE constant as #{reusable}" do
#     expect(klass::REUSABLE).to eq(reusable)
#   end
# end

# shared_examples "provider_data_store" do
#   it "should set the provider id" do
#     @service.set_provider_id
#     expect(@service.provider_id).to eq(@provider_id)
#   end

#   it "should set the provider vpc id" do
#     @service.set_provider_vpc_id
#     expect(@service.provider_vpc_id).to eq(@provider_vpc_id)
#   end
# end

# shared_examples "aws_attribute_formater" do |aws_service, keys|
#   before(:all) {
#     @attributes = described_class.format_attributes_by_raw_data(aws_service)
#   }

#   keys.each do|key|
#     it "should have key #{key}" do
#       expect(@attributes).to have_key(key)
#     end
#   end
# end

# shared_examples "data_store_common_attribute_mapper" do
#   subject { described_class }
#   it { should respond_to(:get_data_store_attributes)}
# end