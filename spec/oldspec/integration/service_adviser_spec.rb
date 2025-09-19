# frozen_string_literal: true

# describe 'AWS Service Adviser' do
#   path '/aws/service_advisers/list_service_type_with_count' do
#     get 'get servise adviser services' do
#       tags 'AWS service adviser'
#       security [
#         { :Bearer => [] }
#       ]
#       consumes 'application/json'
#       parameter name: :service_type, in: :query, type: :string, required: false, enum: Api::V2::Aws::ServiceAdvisersController::SERVICE_TYPE.keys
#       parameter name: :adapter_id, in: :query, type: :string, required: true, default: 'all'
#       parameter name: :region_id, in: :query, type: :string, required: false
#       parameter name: :lifecycle, in: :query, type: :string, required: false
#       parameter name: :environment_id, in: :query, type: :string, required: false
#       parameter name: :public_snapshot, in: :query, type: :boolean, required: false, enum: [true, false]
#       parameter name: :per_page, in: :query, type: :integer, required: false, default: 10
#       parameter name: :page, in: :query, type: :integer, required: false, default: 1
#       response '404', 'report not found' do
#         run_test!
#       end
#     end
#   end

#   path '/aws/service_advisers/list_service_type_with_detail' do
#     get 'get servise adviser services' do
#       tags 'AWS service adviser'
#       security [
#         { :Bearer => [] }
#       ]
#       consumes 'application/json'
#       parameter name: :service_type, in: :query, type: :string, required: true, enum: Api::V2::Aws::ServiceAdvisersController::SERVICE_TYPE.keys
#       parameter name: :adapter_id, in: :query, type: :string, required: true, default: 'all'
#       parameter name: :region_id, in: :query, type: :string, required: false
#       parameter name: :lifecycle, in: :query, type: :string, required: false
#       parameter name: :environment_id, in: :query, type: :string, required: false
#       parameter name: :public_snapshot, in: :query, type: :boolean, required: false, enum: [true, false]
#       parameter name: :per_page, in: :query, type: :integer, required: false, default: 10
#       parameter name: :page, in: :query, type: :integer, required: false, default: 1
#       response '404', 'report not found' do
#         run_test!
#       end
#     end
#   end

#   path '/aws/service_advisers/get_key_values_array' do
#     get 'AWS service adviser tag keys list' do
#       tags 'AWS service adviser'
#       security [
#         { :Bearer => [] }
#       ]
#       consumes 'application/json'
#       parameter name: :service_type, in: :query, type: :string, required: false
#       parameter name: :adapter_id, in: :query, type: :array, items: { type: :string }, required: true, default: 'all'
#       parameter name: :region_id, in: :query, ttype: :array, items: { type: :string }, required: false

#       response '404', 'report not found' do
#         run_test!
#       end
#     end
#   end
# end
