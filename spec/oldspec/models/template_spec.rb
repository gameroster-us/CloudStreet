# require 'spec_helper'
# 
# describe Template do
#   let(:from_unhealthy_to_archived) do
#     OpenStruct.new({
#       :state_field => :state,
#       :name => :archive,
#       :from => :unhealthy,
#       :to => :archived
#     })
#   end
# 
#   it { should validate_numericality_of(:revision) }
# 
#   it { should belong_to(:account) }
#   it { should belong_to(:adapter) }
#   it { should belong_to(:region) }
#   it { should belong_to(:creator).with_foreign_key(:created_by).class_name('User') }
#   it { should belong_to(:updator).with_foreign_key(:updated_by).class_name('User') }
#   it { should have_many(:template_services) }
#   it { should have_many(:services).through(:template_services).dependent(:destroy) }
# 
#   it { should have_transition from_unhealthy_to_archived }
#   before(:all) do
#     @new_template = Template.new
#     @default_revision = @new_template.revision
#   end
# 
#   describe 'attribute revision' do
#     subject { @new_template.revision }
#     it { is_expected.to be_a(Float) }
#     it { is_expected.to eq(0.00) }
#   end
# 
#   describe 'MINOR_REVISION_CHANGE_STEP' do
#     subject { Template::MINOR_REVISION_CHANGE_STEP }
#     it { is_expected.to be_a(Float) }
#   end
# 
#   describe '#increment_minor_revision' do
#     before(:all) { @incremented_template = Template.new; @incremented_template.increment_minor_revision }
# 
#     it 'increments the revision by one minor step' do
#       expect(@incremented_template.revision).to eq(@default_revision + Template::MINOR_REVISION_CHANGE_STEP)
#     end
# 
#     it 'does not save the object while incrementing' do
#       expect(@incremented_template.persisted?).to be false
#     end
#   end
# 
#   describe '#set_shared_with_attribute_of_template' do
# 
#     let(:user) { FactoryBot.build(:user_vpc, :id => 1) }
# 
#     it 'sets the shared_with attribute to the user id if user has set the access as only me' do
#       @new_template.set_shared_with_attribute_of_template(user, "0", [])
#       expect(@new_template.shared_with).to eq([user.id])
#     end
# 
#     it 'sets the shared_with attribute to blank array if it is shared with everyone' do
#       @new_template.set_shared_with_attribute_of_template(user, "2", [])
#       expect(@new_template.shared_with).to eq([])
#     end
# 
#     it 'sets the shared_with attribute to user_role ids if it is shared with specific roles' do
#       user_role_ids = [1, 2]
#       @new_template.set_shared_with_attribute_of_template(user, "1", user_role_ids)
#       expect(@new_template.shared_with).to eq(user_role_ids)
#     end
# 
#   end
# 
#   describe '.search_user_accessible_templates' do
# 
#     let(:user) { FactoryBot.build(:user_vpc, :id => "9c34a608-04d4-4175-80a4-975b245443d1") }
# 
# 
#     before(:all) do
#       @account = FactoryBot.create(:account, :with_user)
#       @template_1 = FactoryBot.create(:template, :account => @account, :created_by => "9c34a608-04d4-4175-80a4-975b245443d1", :shared_with => [])
#     end
# 
#     it 'fetches the accessible templates including user created templates' do
#       fetched_templates = Template.search_user_accessible_templates(user)
#       expect(fetched_templates.count).to eq(1)
#       expect(fetched_templates[0].id).to eq(@template_1.id)
#     end
# 
#     it 'fetches the templates shared with all users' do
#       fetched_templates = Template.search_user_accessible_templates(user)
#       expect(fetched_templates.count).to eq(1)
#       expect(fetched_templates[0].id).to eq(@template_1.id)
#     end
# 
#     it 'fetches the accessible templates including the templates which are shared only to the user' do
#       @template_3 = FactoryBot.create(:template, :account => @account, :created_by => "9c34a608-04d4-4175-80a4-975b245443d1", :shared_with => ["9c34a608-04d4-4175-80a4-975b245443d1"])
#       fetched_templates = Template.search_user_accessible_templates(user)
#       expect(fetched_templates.count).to eq(2)
#       expect(fetched_templates[1].id).to eq(@template_3.id)
#     end
# 
#     it 'fetches the accessible templates which are shared to the users role' do
#       FactoryBot.create(:user_role, :id => "89e60721-7914-4274-95ab-1d63081c6531")
#       user.user_role_ids = ["89e60721-7914-4274-95ab-1d63081c6531"]
#       @template_4 = FactoryBot.create(:template, :account => @account, :created_by => "9c34a608-04d4-4175-80a4-975b245443d0", :shared_with => ["89e60721-7914-4274-95ab-1d63081c6531"])
#       fetched_templates = Template.search_user_accessible_templates(user)
#       expect(fetched_templates.count).to eq(2)
#       expect(fetched_templates[1].id).to eq(@template_4.id)
#     end
# 
#   end
# 
# end
