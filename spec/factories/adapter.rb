require 'faker'
FactoryBot.define do
  factory :adapter do
    name {Faker::Name.name}
    trait :aws do
      type "Adapters::AWS"
    end

    trait :data do
      data {{ access_key_id: ENV.fetch('AWS_BILLING_ACCESS_KEY_ID', 'demo'),
        secret_access_key: ENV.fetch('AWS_BILLING_SECRET_ACCESS_KEY', 'demo_key'),
        aws_account_id: ENV.fetch("AWS_ACCOUNT_ID", 'demo_id'),
        bucket_id: ENV.fetch("BUCKET_ID", 'demo_id'),
        bucket_region_id: ENV.fetch("BUCKET_REGION_ID", 'regin') } }
    end

    trait :data_azure do
      data {{client_id: ENV.fetch('AZURE_NORMAL_BILLING_CLIENT_ID', 'client_id'),
        tenant_id: ENV.fetch('AZURE_NORMAL_BILLING_TENANT_ID', 'azure_id'),
        secret_key: ENV.fetch('AZURE_NORMAL_BILLING_SECRET_KEY', 'demo_key'),
        azure_cloud: "AzureCloud",
        account_setup:"false",
        deployment_model:"arm",
        ea_account_setup:"No",
        azure_account_type:"ss",
        is_management_credentials:"No"}}
    end

    trait :normal do
      adapter_purpose "normal"
    end

    trait :billing do
      adapter_purpose "billing"
    end

    trait :rackspace do
      type "Adapters::Rackspace"
    end

    trait :heroku do
      type "Adapters::Heroku"
    end

    trait :azure do
      type 'Adapters::Azure'
    end

    trait :vm_ware do
      type 'Adapters::VmWare'
    end

    trait :gcp do
      type 'Adapters::GCP'
    end

    trait :backup do
      adapter_purpose "backup"
    end

    trait :directory do
      after(:create) do |obj|
        obj.state = "directory"
        obj.save!
      end
    end

    trait :created do
      after(:create) do  |obj|
        obj.state = "created"
        obj.save!
      end
    end

    trait :activate do
      after(:create) do |obj|
        obj.state = "active"
        obj.save!
      end
    end

    trait :aws_dummy_creds do
      aws
      data { { access_key_id: 'dw2wdddsad', secret_access_key: 'dw2wdddsad' } }
    end

    trait :azure_dummy_creds do
      azure
      data { { client_id: 'dw2wdddsad', secret_key: 'dw2wdddsad', tenant_id: 'dw2wdddsad', deployment_model: "arm" } }
    end

  end


  factory :adapter_aws, class: 'Adapters::AWS', parent: :adapter do
    aws
    association :account
    adapter_purpose "normal"
  end

  factory :adapter_aws_active, class: 'Adapters::AWS', parent: :adapter do
    aws
    activate
    association :account
    adapter_purpose "normal"
  end

  factory :adapter_azure, class: 'Adapters::Azure', parent: :adapter do
    azure
    azure_dummy_creds
    association :account
    adapter_purpose "normal"
  end
  factory :adapter_gcp, class: 'Adapters::GCP', parent: :adapter do
    gcp
    association :account
    adapter_purpose "billing"
    gcp_access_keys JSON.parse(ENV.fetch('GCP_ACCESS_KEYS', '{}'))
    table_name ENV.fetch('TABLE_NAME', 'demo_table')
    dataset_id ENV.fetch('DATASET_ID', 'demo_id')
  end
end
