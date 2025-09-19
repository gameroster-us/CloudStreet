# FactoryBot.define do
#   factory :template_event, class: Events::Template do
#     ignore do
#       revision_no 0.00
#     end

#     account
#     data {{ 'revision_data' => { 'number' => revision_no }  }}

#     trait :revision_changer do
#       after(:build) { |te| te.data['revision_changer'] = true }
#     end

#     trait :edit_service_with_attr_change do
#       after(:build) do |te|
#         te.data['revision_data']['services_data'] ||= {}
#         te.data['revision_data']['services_data']['e6e59511-eeae-4bb7-9b92-0c849081d2c1'] = {
#           'action' => 'edited',
#           'properties' => { 'name' => 'somevpc', 'vpc_id' => 'vpc-ff73c491', 'cidr_block' => '10.41.0.0/16', 'internet_attached' => false, 'enable_dns_hostnames' => false, 'enable_dns_resolution' => false },
#           'generic_type' => 'Services::Vpc',
#           'changed_properties' => ['name', 'internet_attached']
#         }
#       end
#     end

#     trait :edit_service_no_attr_change do
#       after(:build) do |te|
#         te.data['revision_data']['services_data'] ||= {}
#         te.data['revision_data']['services_data']['e6e59511-eeae-4bb7-9b92-0c849081d2c2'] = {
#           'action' => 'edited',
#           'properties' => { 'name' => 'somevpc2', 'vpc_id' => 'vpc-ff73c492', 'cidr_block' => '10.42.0.0/16', 'internet_attached' => false, 'enable_dns_hostnames' => false, 'enable_dns_resolution' => false },
#           'generic_type' => 'Services::Vpc',
#           'changed_properties' => []
#         }
#       end
#     end

#     trait :new_service do
#       after(:build) do |te|
#         te.data['revision_data']['services_data'] ||= {}
#         te.data['revision_data']['services_data']['e6e59511-eeae-4bb7-9b92-0c849081d2c3'] = {
#           'action' => 'created',
#           'properties' => { 'name' => 'somevpc3', 'vpc_id' => 'vpc-ff73c493', 'cidr_block' => '10.43.0.0/16', 'internet_attached' => false, 'enable_dns_hostnames' => false, 'enable_dns_resolution' => false },
#           'generic_type' => 'Services::Vpc',
#           'changed_properties' => []
#         }
#       end
#     end

#     trait :deleted_service do
#       after(:build) do |te|
#         te.data['revision_data']['services_data'] ||= {}
#         te.data['revision_data']['services_data']['e6e59511-eeae-4bb7-9b92-0c849081d2c4'] = {
#           'action' => 'deleted',
#           'properties' => { 'name' => 'somevpc4', 'vpc_id' => 'vpc-ff73c494', 'cidr_block' => '10.44.0.0/16', 'internet_attached' => false, 'enable_dns_hostnames' => false, 'enable_dns_resolution' => false },
#           'generic_type' => 'Services::Vpc',
#           'changed_properties' => []
#         }
#       end
#     end
#   end
# end
