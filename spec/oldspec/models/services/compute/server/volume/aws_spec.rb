# require 'spec_helper'
# 
# describe Services::Compute::Server::Volume::AWS do
#   before(:all) do
#     @volume = FactoryBot.create(:service, :volume_aws, :running)
#     @volume = Service.find(@volume.id)
#     volume_metaclass = class << @volume; self; end
#     volume_metaclass.send(:define_method, :set_parent_container_id) do SecureRandom.hex end
#     @volume.set_additional_properties!
#     @environment = FactoryBot.create(:environment, :aws_environment)
#     @response = Object.new
#     @server = FactoryBot.create(:service, :running, :aws, :server_aws)
#     @server.provider_data = { "block_device_mapping" => [{ "volumeId" => "vol-f2c34f0b" }] }
#     EnvironmentService.create(environment_id: @environment.id, service_id: @server.id)
#     @dummy_remote_service = FactoryBot.build(:fog_volume)
#   end
# 
#   describe '#format_attributes_by_raw_data' do
#     @keys = [ :name, :status, :size, :volume_type, :iops, :device, :server_id, :snapshot_id, :availability_zone, :root_device, :state, :tags ]
# 
#     @aws_service = FactoryBot.build(:fog_volume)
# 
#     it_behaves_like "aws_attribute_formater", @aws_service, @keys
#   end
# 
#   describe "#tag_preferenced?" do
#     before(:each) do
#       @user = FactoryBot.create(:user_iam_role)
#       @volume.account = @user.account
#       @volume.save!
#     end
#     it "should return false when prefrence provided is not found" do
#       UserUpdater.update_user_preferences @user.id, { 'sync_guidelines' => "true" }, "Account"
#       expect(@volume.tag_preferenced?).to be false
#     end
#     it "should return false when prefrence provided is false" do
#       UserUpdater.update_user_preferences @user.id, { 'tag_hostname_to_volume' => "false" }, "Account"
#       expect(@volume.tag_preferenced?).to be false
#     end
#     it "should return true when prefrence provided is present" do
#       UserUpdater.update_user_preferences @user.id, { 'tag_hostname_to_volume' => "true" }, "Account"
#       expect(@volume.tag_preferenced?).to be true
#     end
#   end
# 
#   describe ".get_cloudstreet_attach_status" do
#     context "when in-use" do
#       it 'returns attached' do
#         expect(subject.class.get_cloudstreet_attach_status("in-use")).to eq "attached"
#       end
#     end
# 
#     context "when available" do
#       it 'returns detached' do
#         expect(subject.class.get_cloudstreet_attach_status("available")).to eq "detached"
#       end
#     end
#   end
# 
#   describe '#is_root_device' do
#     context 'when root device' do
#       it 'return true' do
#         @volume.root_device = true
#         expect(@volume.is_root_device?).to be true
#       end
#     end
# 
#     context 'when not root device' do
#       it 'return false' do
#         @volume.root_device = false
#         expect(@volume.is_root_device?).to be false
#       end
#     end
#   end
# 
#   describe '#set_additional_properties!' do
#     it 'assigns properties to the volumes additional properties' do
#       required_properties = %w(depends draggable drawable edge generic_type id interfaces internal numbered name state properties provides service_type type vpc_id parent_id primary_key)
#       expect(@volume.additional_properties.keys.map(&:to_s)).to match_array required_properties
#     end
#   end
# 
#   describe "class methods" do
#     before(:each) do
#       allow(@server.environment.default_adapter).to receive(:connection) { " " }
#       allow(subject.class).to receive(:create_volume_service) { true }
#       allow_any_instance_of(ProviderWrappers::AWS::Computes::Volume).to receive(:fetch_remote_volume).and_return(@response)
#     end
# 
#     context ".find_and_create_volume_services" do
#       it "should return the id when volume ids are provided" do
#         expect(subject.class.find_and_create_volume_services(@server)).to eq [{ "volumeId" => "vol-f2c34f0b" }]
#       end
#     end
# 
#     context ".create_volume_service" do
#       it "should create a volume object" do
#         allow(subject.class).to receive(:create_interfaces_n_connections) { true }
#         expect(subject.class.create_volume_service(@hash, @server)).to eq true
#       end
#     end
#   end
#   describe "#create_service_interfaces" do
#     before(:all) do
#       @user = FactoryBot.create(:user_iam_role)
#       @env = FactoryBot.create(:environment, account_id: @user.account_id, revision: 1.0)
# 
#       @vpc = FactoryBot.create(:service, :vpc, :running, account_id: @user.account_id)
#       @vpc = Service.find(@vpc.id)
#       @env.services << @vpc
# 
#       @az = FactoryBot.create(:service, :running, :availability_zone, data: { "code" => "eu-central-1b" })
#       @az = Service.find(@az.id)
#       @env.services << @az
# 
#       @volume = FactoryBot.create(:service, :running, :volume)
#       @volume = Service.find(@volume.id)
#       @env.services << @volume
#     end
# 
#     it "should not create interface for {} params" do
#       expect { @volume.create_service_interfaces({}) }.to change(@volume.reload.interfaces, :count).by(0)
#     end
# 
#     it "should not create interface for invalid params" do
#       params = { service_vpc_id: '9b6e2389-afb2-4ad4-8331-16a54c2d01c8', availability_zone: '' }
#       expect { @volume.create_service_interfaces(params) }.to change(@volume.reload.interfaces, :count).by(0)
#     end
# 
#     it "should create interfaces for valid params with existing availability_zone" do
#       params = { service_vpc_id: @vpc.id, availability_zone: @az.code }
#       expect { @volume.create_service_interfaces(params) }.to change(@volume.reload.interfaces, :count).by(2)
#     end
# 
#     it "should create interfaces for valid params with new availability_zone" do
#       params = { service_vpc_id: @vpc.id, availability_zone: 'eu-central-1b' }
#       expect { @volume.create_service_interfaces(params) }.to change(@volume.reload.interfaces, :count).by(2)
#     end
#   end
# 
#   describe "#can_be_provisioned_using_snapshot?" do
#     before(:all) do
#       parent_snp = FactoryBot.create(:service, :volume_aws, data: { "size" => 2, "volume_type" => "Magnetic" })
#       @parent_snp = Service.find(parent_snp.id)
#     end
# 
#     it 'should not allow to create volume of type io1 without iops' do
#       @volume_from_snapshot = FactoryBot.create(:service, :volume_aws,
#                                                  data: { "size" => 4, "volume_type" => "Provisioned IOPS (SSD)" })
#       @volume_from_snapshot = Service.find(@volume_from_snapshot.id)
#       allow(@volume_from_snapshot).to receive(:parent_snapshot).and_return(@parent_snp)
#       @volume_from_snapshot.can_be_provisioned_using_snapshot?
#       expect(@volume_from_snapshot.errors.messages[:iops]).to include("can't be blank")
#     end
# 
#     it 'should not allow to create volume of type io1 with invalid iops ratio' do
#       @volume_from_snapshot = FactoryBot.create(:service, :volume_aws,
#                                                  data: { "size" => 4, "volume_type" => "Provisioned IOPS (SSD)", "iops" => 200 })
#       @volume_from_snapshot = Service.find(@volume_from_snapshot.id)
#       allow(@volume_from_snapshot).to receive(:parent_snapshot).and_return(@parent_snp)
#       @volume_from_snapshot.can_be_provisioned_using_snapshot?
#       expect(@volume_from_snapshot.errors.messages[:iops]).to include("Maximum ratio of 50:1 is permitted between IOPS and volume size")
#     end
# 
#     it 'should not allow to create volume with size less than snapshot size' do
#       @volume_from_snapshot = FactoryBot.create(:service, :volume_aws, data: { "size" => 1, "volume_type" => "Magnetic" })
#       @volume_from_snapshot = Service.find(@volume_from_snapshot.id)
#       allow(@volume_from_snapshot).to receive(:parent_snapshot).and_return(@parent_snp)
#       @volume_from_snapshot.can_be_provisioned_using_snapshot?
#       expect(@volume_from_snapshot.errors.messages[:size]).to include("Min: 2GiB, Max: 1024GiB")
#     end
# 
#     it 'should allow to create volume with size greater than snapshot size' do
#       @volume_from_snapshot = FactoryBot.create(:service, :volume_aws, data: { "size" => 3, "volume_type" => "Magnetic" })
#       @volume_from_snapshot = Service.find(@volume_from_snapshot.id)
#       allow(@volume_from_snapshot).to receive(:parent_snapshot).and_return(@parent_snp)
#       expect(@volume_from_snapshot.can_be_provisioned_using_snapshot?).to eql true
#     end
#   end
# 
#   describe ".check_encryption_key_presence" do
#     before(:each) do
#       @account ||= FactoryBot.create(:account, :with_user)
#       @adapter ||= FactoryBot.create(:adapter, :aws, account_id: @account.id)
#       @region ||= FactoryBot.create(:region, code: 'eu-central-1')
#       @encryption_key = FactoryBot.create(:encryption_key,
#       key_id: 'f8f98681-7b61-4845-bd7c-0218b3cac468',
#       adapter_id: @adapter.id,
#       region_id: @region.id, account_id: @account.id)
#       allow(@volume).to receive(:encryption_key).and_return(@encryption_key)
#     end
# 
#     it "should raise error for disabled/deleted key" do
#       allow(EncryptionKeysSearcherService).to receive(:check_encryption_key).and_return(false)
#       expect { @volume.send(:check_encryption_key_presence) }.to raise_error(RuntimeError)
#     end
# 
#     it "should not raise error for active key" do
#       allow(EncryptionKeysSearcherService).to receive(:check_encryption_key).and_return(true)
#       expect { @volume.send(:check_encryption_key_presence) }.not_to raise_error
#     end
#   end
# end
