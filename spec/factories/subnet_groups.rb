# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :base_subnet_group do
    name "MyString"
    provider_id "MyString"
    description "MyText"
    provider_vpc_id "MyString"
    status "MyString"
    account
    region
    vpc_id ""
    data ""
  end
end
