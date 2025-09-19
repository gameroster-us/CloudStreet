require "faker"
FactoryBot.define do
  factory :organisation_image do
    account
    image_name {Faker::Address.state_abbr}
    machine_image
    image_data {{:root_device_type => "abx" , :virtualization_type =>  "abx", :platform =>  "x86", :userdata => ""    }}
  end
  trait :with_roles_as_array do
    user_role_ids {[]}
  end
  trait :with_roles_to_explicit_nil do
    user_role_ids {nil}
  end
  trait :with_roles_as_nil do
    user_role_ids {"{nil}"}
  end
  trait :with_roles_as_empty do
    user_role_ids {"{''}"}
  end
  trait :with_roles_as_non_uuid do
    user_role_ids {"{some non uuid value}"}
  end

  trait :with_instance_types do
    instance_types {"t1.micro,t2.micro,t2.small,t2.medium,m3.medium,m3.large,m3.xlarge,m3.2xlarge,m1.small,m1.medium,m1.large,m1.xlarge,c3.large,c3.xlarge,c3.2xlarge,c3.4xlarge,c3.8xlarge,c1.medium,c1.xlarge,cc2.8xlarge,cc1.4xlarge,g2.2xlarge,cg1.4xlarge,r3.large,r3.xlarge,r3.2xlarge,r3.4xlarge,r3.8xlarge,m2.xlarge,m2.2xlarge,m2.4xlarge,cr1.8xlarge,i2.xlarge,i2.2xlarge,i2.4xlarge,i2.8xlarge,hi1.4xlarge,hs1.8xlarge"}
  end
end
