# require 'spec_helper'
# 
# describe Application do
#   it "has a valid factory" do
#     expect(FactoryBot.create(:application)).to be_valid
#   end
# 
#   # Testing validations
#   it "is invalid without a application name" do
#   	expect(FactoryBot.build(:application, name: nil)).not_to be_valid
#   end
# 
#   it "is invalid with a application name exceeding 255 characters" do
#   	expect(FactoryBot.build(:application, :application_with_lengthy_name)).not_to be_valid
#   end
# 
#   it "is invalid without a organisation account" do
#     expect(FactoryBot.build(:application, account_id: nil)).not_to be_valid
#   end
# 
#   it "is invalid without a creator" do
#     expect(FactoryBot.build(:application, created_by_user_id: nil)).not_to be_valid
#   end
# end
