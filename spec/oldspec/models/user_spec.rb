# require "spec_helper"
# 
# describe User do
#   describe 'new user object' do
#     subject { User.new }
# 
#     its(:show_intro) { should be true }
#   end
# 
#   describe "#exception_for_ip_auto_correct?" do
#     before(:all) do
#       @account, @user_env = power_user
#       @user = @account.users.first
#     end
# 
#     it 'should return true if exception for IP auto correct is enabled for current user role' do
#       expect(@user.exception_for_ip_auto_correct?).to eql true
#     end
# 
#     it 'should return false if exception for IP auto correct is disabled for current user role' do
#       access_right = AccessRight.find_by_code('cs_exception_for_ip_auto_correct')
#       access_right_user_role = @user.user_roles.joins(:rights).where("access_rights_user_roles"=>{access_right_id: access_right.id})
#       access_right_user_role.destroy_all
#       expect(@user.exception_for_ip_auto_correct?).to eql false
#     end
#   end
# 
#   # describe "abilities" do
#   #   subject(:ability){ Ability.new(user) }
#   #   let(:user){ nil }
# 
#   #   context "when listing environments" do
#   #     let(:user){ User.new }
# 
#   #     it{ should be_able_to(:index, Environment.new) }
#   #   end
# 
#   #   context "when environment belongs to a user's account" do
#   #     let(:user) { User.new }
# 
#   #     it { should be_able_to(:show, Environment.new) }
#   #   end
#   # end
# 
#   describe "#has_exception_for_naming_convention?" do
#     before(:all) do
#       @account, @user_env = power_user
#       @user = @account.users.first
#     end
# 
#     it 'should return true if exception for naming convention is enabled for current user role' do
#       expect(@user.has_exception_for_naming_convention?).to eql true
#     end
# 
#     it 'should return false if exception for naming convention is disabled for current user role' do
#       access_right = AccessRight.find_by_code('cs_exception_for_naming_convention')
#       access_right_user_role = @user.user_roles.joins(:rights).where("access_rights_user_roles"=>{access_right_id: access_right.id})
#       access_right_user_role.destroy_all
#       expect(@user.has_exception_for_naming_convention?).to eql false
#     end
#   end
# 
#   describe "#credentials_updated?" do
#     it 'should return true if username is changed' do
#       user = FactoryBot.create(:user)
#       user.username = "testuser"
#       expect(user.credentials_updated?).to eql true
#     end
# 
#     it 'should return true if password is changed' do
#       user = FactoryBot.create(:user)
#       user.password = "password"
#       expect(user.credentials_updated?).to eql true
#     end
# 
#     it 'should return false if there is no change in username & encrypted_password' do
#       user = FactoryBot.create(:user)
#       user.name = "testname"
#       expect(user.credentials_updated?).to eql false
#     end
#   end
# end
