# require "spec_helper"

# describe "VpcAuthorizer" do
#   let(:owner)   { FactoryBot.create(:user) }
#   let(:user)    { FactoryBot.create(:user) }
#   let(:account) { owner.account }
#   let(:member) do
#     member = FactoryBot.create(:user)
#     group = account.groups.where(name: "members").first_or_create!
#     group.add_user(member)

#     member
#   end

#   let(:vpc) { FactoryBot.create(:vpc, :aws_region, account_id: account.id) }

#   describe "readable_by?" do
#     it "allows account owners to read" do
#       expect(vpc.authorizer).to be_readable_by(owner)
#     end

#     it "allows account members to read" do
#       expect(vpc.authorizer).to be_readable_by(member)
#     end

#     it "doesn't allow other users to read" do
#       expect(vpc.authorizer).not_to be_readable_by(user)
#     end
#   end

#   describe "creatable_by?" do
#     it "allows account owners to create" do
#       expect(vpc.authorizer).to be_creatable_by(owner, { account_id: owner.account.id })
#     end

#     it "doesn't allow members to create" do
#       expect(vpc.authorizer).not_to be_creatable_by(member, { account_id: owner.account.id })
#     end

#     it "doesn't allow other users to create" do
#       expect(vpc.authorizer).not_to be_creatable_by(user, { account_id: owner.account.id })
#     end
#   end
# end
