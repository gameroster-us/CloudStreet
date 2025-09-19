# 
# require 'spec_helper'
# 
# describe AWSRecord do
# 
#   describe "validations" do
# #    it { should validate_presence_of :adapter_id }
# #    it { should validate_presence_of(:account_id) }
# #    it { should validate_presence_of(:region_id) }
#    end
#   describe ".get_service_type" do
#     it "should map the service types with its corresponding data store classes" do
#       expect(subject.class.get_service_type("VPC")).to be AWSRecords::Network::Vpc::AWS
#       expect(subject.class.get_service_type("SecurityGroup")).to be AWSRecords::Network::SecurityGroup::AWS
#       expect(subject.class.get_service_type("Subnet")).to be AWSRecords::Network::Subnet::AWS
#       expect(subject.class.get_service_type("RDS::SubnetGroup")).to be AWSRecords::Network::SubnetGroup::AWS
#       expect(subject.class.get_service_type("RouteTable")).to be AWSRecords::Network::RouteTable::AWS
#       expect(subject.class.get_service_type("ELB::LoadBalancer")).to be AWSRecords::Network::LoadBalancer::AWS
#       expect(subject.class.get_service_type("AutoScaling::Group")).to be AWSRecords::Network::AutoScaling::AWS
#       expect(subject.class.get_service_type("AutoScaling::Configuration")).to be AWSRecords::Network::AutoScalingConfiguration::AWS
#       expect(subject.class.get_service_type("InternetGateway")).to be AWSRecords::Network::InternetGateway::AWS
#       expect(subject.class.get_service_type("RDS::Server")).to be AWSRecords::Database::Rds::AWS
#       expect(subject.class.get_service_type("Volume")).to be AWSRecords::Compute::Server::Volume::AWS
#       expect(subject.class.get_service_type("Address")).to be AWSRecords::Network::ElasticIp::AWS
#       expect(subject.class.get_service_type("NetworkAcl")).to be AWSRecords::Network::Nacl::AWS
#       expect(subject.class.get_service_type("Snapshot")).to be AWSRecords::Snapshots::Volume::AWS
#       expect(subject.class.get_service_type("RDS::Snapshot")).to be AWSRecords::Snapshots::Rds::AWS
#     end
#   end
# 
#   describe AWSRecord::CommonAttributeMapper do
#     describe ".sort" do
#       before(:all){
#         @unsorted_services = AWSRecord::SERVICES_ORDER.inject([]) do |services, type|
#           services.push(FactoryBot.build(:aws_record, service_type: type))
#         end
#       }
#       it "should have arrange services in the respective dependency order" do
#         services = AWSRecord.sort(@unsorted_services)
#         expect(services.map(&:service_type)).to eq([
#           "SecurityGroup", "Subnet", "RouteTable", "Server", "InternetGateway", "VPC",
#           "RDS::SubnetGroup", "RDS::Server", "Volume", "ELB::LoadBalancer",
#           "AutoScaling::Group", "AutoScaling::Configuration", "NetworkAcl", "Snapshot","RDS::Snapshot","NetworkInterface", "Address"
#         ])
#       end
#     end
#     describe ".get_data_store_attributes" do
#       before(:all){
#         @data_store_record = FactoryBot.build(:aws_record, {
#           account_id: SecureRandom.hex,
#           adapter_id: SecureRandom.hex,
#           region_id: SecureRandom.hex,
#           provider_id: "xyz",
#           data: {}
#         })
#         Service.extend(AWSRecord::CommonAttributeMapper)
#         @attributes = Service.get_data_store_attributes(@data_store_record)
#       }
# 
#       it "should have key account_id" do
#         expect(@attributes).to have_key(:account_id)
#       end
# 
#       it "should have key adapter_id" do
#         expect(@attributes).to have_key(:adapter_id)
#       end
# 
#       it "should have key region_id" do
#         expect(@attributes).to have_key(:region_id)
#       end
# 
#       it "should have key provider_data" do
#         expect(@attributes).to have_key(:provider_data)
#       end
# 
#       it "should have key provider_id" do
#         expect(@attributes).to have_key(:provider_data)
#       end
#     end
#   end
# end
