# require "spec_helper"

# describe "ServiceDefaultNamingAuthorizer" do
#   before(:each) do
#     @owner ||=  FactoryBot.build(:user_iam_role)
#     @user ||=   FactoryBot.build(:user_iam_role)
#     @account ||=  @owner.account
#     @member = FactoryBot.build(:user_iam_role)
#     group = @account.groups.where(name: "members").first_or_create!
#     group.add_user(@member)
#     @account.create_general_setting(naming_convention_enabled: true)
#     @service_naming_default ||= FactoryBot.create(:service_naming_default, account: @account)
#   end

#   describe "updatable_by?" do
#     it "allows account owners to create" do
#       expect(@service_naming_default.authorizer).to be_updatable_by(@owner)
#     end

#     it "doesn't allow members to create" do
#       expect(@service_naming_default.authorizer).not_to be_updatable_by(@member)
#     end

#     it "doesn't allow other users to create" do
#       expect(@service_naming_default.authorizer).not_to be_updatable_by(@user)
#     end
#   end
# end
