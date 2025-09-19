# require 'spec_helper'
# 
# describe "Behaviors::ServiceRestrictable" do
# 
#   before(:all) do
#     @user = FactoryBot.create(:user_ami)
#   end
# 
#   subject { OrganisationImage.include(Behaviors::ServiceRestrictable) }
#   context "os-restrictions for the users" do
# 
#     it "should return an active relation on method" do
#       expect(OrganisationImage.user_accessible_params(@user)).to be_a(ActiveRecord::Relation)
#     end
# 
#     it "shall return empty if no image is added by organisation" do
#       no_images = subject.user_accessible_params(@user)
#       expect(no_images).to match_array([])
#     end
# 
#     it "shall show all the images whose role ids are not assigned" do
#       FactoryBot.create(:organisation_image, account_id: @user.account.id)
#       every_one_amis = subject.user_accessible_params(@user)
#       expect(every_one_amis.first.user_role_ids).to eql([])
#     end
# 
#     it "shall show only one image if assigned to only one role" do
#       FactoryBot.create(:organisation_image, account_id: @user.account.id, user_role_ids: [@user.user_roles.first.id])
#       every_one_amis = subject.user_accessible_params(@user)
#       expect(every_one_amis.first.user_role_ids).to eql([@user.user_roles.first.id])
#     end
# 
#     # xit "shall show images only of the users organisation" do
#     #   FactoryBot.create(:organisation_image, account_id: @user.account.id)
#     #   every_one_amis = subject.user_specific_images(@user)
#     #   expect(every_one_amis.first.user_role_ids).to eql([@user.user_roles.first.id])
#     # end
# 
#     it "shall include only the images accessible by the users role" do
#       FactoryBot.create(:organisation_image, account_id: @user.account.id, user_role_ids: [@user.user_roles.first.id])
#       every_one_amis = subject.user_accessible_params(@user)
#       expect(every_one_amis.first.user_role_ids).not_to eql([SecureRandom.hex])
#     end
# 
#   end
# end
