require 'faker'
FactoryBot.define do
  factory :environment do
    name { Faker::Name.first_name }
    environment_model { { this: 'is', only: 'a', test: { hash: 'map' } } }
    account
    user_role_ids {[]}
    data {{ 'restricted' => false}}

    trait :running do
      state "running"
    end

    trait :unhealthy do
      state "unhealthy"
    end

    trait :with_service do
      services { create_list :environmented_service, 1, :server, :aws }
    end

    trait :with_service_rds do
      services { create_list :environmented_service, 1, :rds_aws_postgres }
    end

    trait :for_region_sa_east_1 do
      association :region, :aws_adapter, code: 'sa_east_1'
    end

    trait :for_region_us_west_1 do
      association :region, :aws_adapter, code: 'us_west_1'
    end

    trait :aws_environment do
      association :region, :aws_adapter

      after(:build) do |environment_obj|
        environment_obj.default_adapter = environment_obj.region.adapter
      end
    end

    trait :with_services do
      services { create_list :environmented_service, 2, :server, :aws }
    end

    trait :with_two_services do
      running
      services { create_list :service, 2, :server, :running }
    end

    trait :with_two_servers_removed_from_provider do
      unhealthy
      services { create_list :service, 2, :server, :removed_from_provider }
    end

    trait :with_revision do
      revision 1.0
    end
    # after(:create) do |environment|
    #   vpc    = FactoryBot.create(:service, :vpc)
    #   subnet = FactoryBot.create(:service, :subnet)
    #   #subnet.add_relationship(:vpc, vpc, Protocol::Subnet)

    #   environment.services << [vpc, subnet]
    # end
  end
end
