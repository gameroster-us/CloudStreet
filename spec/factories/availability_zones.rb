FactoryBot.define do
  factory :availability_zone do
  	zone_name "south-east"
  	association :region, factory: :region
  end
end
