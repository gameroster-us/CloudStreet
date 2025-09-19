# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :permission do
    user_id 1
    name "MyString"
    subject_class "MyString"
    subject_id 1
    action "MyString"
    description "MyText"
  end
end
