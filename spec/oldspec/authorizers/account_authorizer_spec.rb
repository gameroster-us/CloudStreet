# require "spec_helper"

# describe "AccountAuthorizer" do
#   let(:owner)   { FactoryBot.create(:user) }
#   let(:user)    { FactoryBot.create(:user) }
#   let(:account) { owner.account }
#   let(:member) do
#     member = FactoryBot.create(:user)
#     group = account.groups.where(name: "members").first_or_create!
#     group.add_user(member)

#     member
#   end

#   describe "readable_by?" do
#     it "allows account owners to read" do
#       expect(account.authorizer).to be_readable_by(owner)
#     end

#     it "allows account members to read" do
#       expect(account.authorizer).to be_readable_by(member)
#     end

#     it "doesn't allow other users to read" do
#       expect(account.authorizer).not_to be_readable_by(user)
#     end
#   end

#   describe "updatable_by?" do
#     it "allows account owners to update" do
#       expect(account.authorizer).to be_updatable_by(owner)
#     end

#     it "doesn't allow members to update" do
#       expect(account.authorizer).not_to be_updatable_by(member)
#     end

#     it "doesn't allow other users to update" do
#       expect(account.authorizer).not_to be_updatable_by(user)
#     end
#   end

#   describe "deletable_by?" do
#     it "allows account owners to delete" do
#       expect(account.authorizer).to be_deletable_by(owner)
#     end

#     it "doesn't allow members to delete" do
#       expect(account.authorizer).not_to be_deletable_by(member)
#     end

#     it "doesn't allow other users to delete" do
#       expect(account.authorizer).not_to be_deletable_by(user)
#     end
#   end

  # TODO: do we need a create test? We don't allow it via the API atm

# end
