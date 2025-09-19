# # Read about factories at https://github.com/thoughtbot/factory_girl

# FactoryBot.define do
#   factory :subscription do
#     provider_subscription_id "test_subscription"
#     name "test_subscription_id"
#     state "Enabled"
#     enabled true

#     trait :azure do
#       type "Subscriptions::Azure"
#     end

#   end

#   factory :subscription_azure, class: Subscriptions::Azure, parent: :subscription do
#     azure
#   end
# end
