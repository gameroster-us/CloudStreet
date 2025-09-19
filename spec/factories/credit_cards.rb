# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :credit_card do
    card_holder "MyString"
    card_number "MyString"
    card_expiry "2016-06-08 09:27:32"
    authorized false
    response_data ""
  end
end
