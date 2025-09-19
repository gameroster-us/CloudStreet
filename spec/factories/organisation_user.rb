FactoryBot.define do
  factory :organisation_user do
    association :organisation
    association :user
    state { "active" }
  end
end