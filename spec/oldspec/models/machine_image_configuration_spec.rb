# require 'spec_helper'
# 
# describe MachineImageConfiguration do
# 
#   context "associations" do
#     it { should belong_to(:organisation_image) }
#   end
# 
#   it "has a valid factory" do
#     expect(FactoryBot.create(:machine_image_configuration, :mic_with_roles_as_array)).to be_valid
#   end
# 
#   it "user_role_ids must be of class Array" do
#     expect(FactoryBot.create(:machine_image_configuration).user_role_ids).to be_kind_of(Array)
#   end
# 
#   describe "callbacks to set roles" do
#     before(:each) do
#       @machine_image_configuration_with_explicit_nil ||= FactoryBot.create(:machine_image_configuration, :mic_with_roles_to_explicit_nil)
#       puts "#{@machine_image_configuration_with_explicit_nil.inspect}"
#     end
# 
#     it "user_role_ids class must be an Array if provided as nil" do
#       expect(@machine_image_configuration_with_explicit_nil.user_role_ids).to be_kind_of(Array)
#     end
# 
#     it "should set roles to be empty if provided as nil" do
#       expect(@machine_image_configuration_with_explicit_nil.user_role_ids).to be_empty
#     end
#    end
# 
#    describe "should not create" do
#     before(:each) do
#       @configuration_with_organisation_image_id_and_name ||= FactoryBot.create(:machine_image_configuration, organisation_image_id: 4, name: 'config a' )
#     end
# 
#     it "machine image configuration without same name for same organisation" do
#       @dup_config = FactoryBot.create(:machine_image_configuration, organisation_image_id: 4)
#       @dup_config.name = @configuration_with_organisation_image_id_and_name.name
#       expect(@dup_config).to_not be_valid
#     end
# 
#    end
# 
# end
