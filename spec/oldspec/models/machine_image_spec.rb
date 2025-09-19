# require 'spec_helper'
# 
# describe MachineImage do
#   before(:all) do
#     @directory_adapter = FactoryBot.create(:adapter, :aws, :directory)
#     @private_adapter = FactoryBot.create(:adapter, :aws, :activate)
#     @region = FactoryBot.create(:region)
#     @aws_aws_data = FactoryBot.create(:fog_aws_ami)
#   end
#   context "constants" do
#     it "should have NON_WINDOWS constant" do
#       expect(subject.class).to have_constant(:NON_WINDOWS)
#     end
#   end
# 
#   describe ".create_machine_image" do
#     before(:each) do
#       @ami = MachineImage.create_machine_image(@private_adapter, @region, @aws_aws_data)
#     end
# 
#     it "should create the AMI" do
#       expect(@ami.persisted?).to be true
#     end
# 
#     it "should have set active property to be true" do
#       expect(@ami.active).to eq(true)
#     end
# 
#     it "should have set name property" do
#       expect(@ami.name).to eq(@aws_aws_data["name"])
#     end
# 
#     it "should have set architecture property" do
#       expect(@ami.architecture).to eq(@aws_aws_data["architecture"])
#     end
# 
#     it "should have set description property" do
#       expect(@ami.description).to eq(@aws_aws_data["description"])
#     end
# 
#     it "should have set image_id property" do
#       expect(@ami.image_id).to eq(@aws_aws_data["imageId"])
#     end
# 
#     it "should have set image_location property" do
#       expect(@ami.image_location).to eq(@aws_aws_data["imageLocation"])
#     end
# 
#     it "should have set image_state property" do
#       expect(@ami.image_state).to eq(@aws_aws_data["imageState"])
#     end
# 
#     it "should have set image_type property" do
#       expect(@ami.image_type).to eq(@aws_aws_data["imageType"])
#     end
# 
#     it "should have set image_owner_alias property" do
#       expect(@ami.image_owner_alias).to eq(@aws_aws_data["imageOwnerAlias"])
#     end
# 
#     it "should have set image_owner_id property" do
#       expect(@ami.image_owner_id).to eq(@aws_aws_data["imageOwnerId"])
#     end
# 
#     it "should have set product_codes property" do
#       expect(@ami.product_codes).to eq(@aws_aws_data["productCodes"])
#     end
# 
#     it "should have set is_public property" do
#       expect(@ami.is_public).to eq(@aws_aws_data["isPublic"])
#     end
# 
#     it "should have set kernel_id property" do
#       expect(@ami.kernel_id).to eq(@aws_aws_data["kernelId"])
#     end
# 
#     it "should have set platform property" do
#       expect(@ami.platform).to eq(@aws_aws_data["platform"])
#     end
# 
#     it "should have set ramdisk_id property" do
#       expect(@ami.ramdisk_id).to eq(@aws_aws_data["ramdiskId"])
#     end
# 
#     it "should have set root_device_name property" do
#       expect(@ami.root_device_name).to eq(@aws_aws_data["rootDeviceName"])
#     end
# 
#     it "should have set root_device_type property" do
#       expect(@ami.root_device_type).to eq(@aws_aws_data["rootDeviceType"])
#     end
# 
#     it "should have set virtualization_type property" do
#       expect(@ami.virtualization_type).to eq(@aws_aws_data["virtualizationType"])
#     end
# 
#   end
# 
#   describe ".get_owner_id_from_provider" do
#     context "when ubuntu" do
#       it "should return the official ubuntu owner id" do
#         expect(MachineImage.get_owner_id_from_provider("ubuntu")).to eq("099720109477")
#       end
#     end
#     context "when redhat" do
#       it "should return the official redhat owner id" do
#         expect(MachineImage.get_owner_id_from_provider("redhat")).to eq("309956199498")
#       end
#     end
#     context "when fedora" do
#       it "should return the official fedora owner id" do
#         expect(MachineImage.get_owner_id_from_provider("fedora")).to eq("125523088429")
#       end
#     end
#     context "when debian" do
#       it "should return the official debian owner id" do
#         expect(MachineImage.get_owner_id_from_provider("debian")).to eq("379101102735")
#       end
#     end
#     context "when gentoo" do
#       it "should return the official gentoo owner id" do
#         expect(MachineImage.get_owner_id_from_provider("gentoo")).to eq("902460189751")
#       end
#     end
#     context "when opensuse" do
#       it "should return the official opensuse owner id" do
#         expect(MachineImage.get_owner_id_from_provider("opensuse")).to eq("056126556840")
#       end
#     end
#     context "when invalid provider" do
#       it "should return nil" do
#         expect(MachineImage.get_owner_id_from_provider("invalid")).to eq(nil)
#       end
#     end
#   end
# 
#   describe ".get_image_params" do
#     context "when Windows machine image" do
#       it "should have set the platform to windows" do
#         @aws_service = FactoryBot.build(:fog_server,platform: "windows")
#         params = subject.class.get_image_params(@aws_service)
#         expect(params[:platform]).to eq "windows"
#       end
#     end
# 
#     context "when Non-Windows machine image" do
#       it "should have set the platform to non-windows" do
#         @aws_service = FactoryBot.build(:fog_server,platform: nil)
#         params = subject.class.get_image_params(@aws_service)
#         expect(params[:platform]).to eq MachineImage::NON_WINDOWS
#       end
#     end
#   end
# 
#   describe ".archive_inactive_amis" do
#     before(:all) do
#       @other_region = FactoryBot.create(:region)
#       @ami_of_other_region = FactoryBot.create(:machine_image, is_public: 't', active: true, adapter: @directory_adapter, region: @other_region)
#       @active_ami = FactoryBot.create(:machine_image, is_public: 't', active: true, adapter: @directory_adapter, region: @region)
#       @deleted_ami = FactoryBot.create(:machine_image, is_public: 't', active: true, adapter: @directory_adapter, region: @region, image_id: "ami-lh6gf324")
#       @active_ami_ids = ["ami-ef4gf322","ami-rf4mf5jk","ami-iftaw3fq", @active_ami.image_id]
#       MachineImage.archive_inactive_amis(@directory_adapter, @region, @active_ami_ids)
#     end
# 
#     xit "should change the deleted AMIs active field to false" do
#       #to be checked later
#       @deleted_ami.reload
#       expect(@deleted_ami.active).to be false
#     end
# 
#     it "should not update the active field of amis still active " do
#       @active_ami.reload
#       expect(@active_ami.active).to be true
#     end
# 
#     it "should not update the active field of those amis of other regions" do
#       @ami_of_other_region.reload
#       expect(@ami_of_other_region.active).to be true
#     end
#   end
# end
