# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :template_cost do
    region
    data "us-west-1"=>{}
  end
end
