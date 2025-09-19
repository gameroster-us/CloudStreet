# describe 'Service Manager' do

#   path '/aws/service_manager/servers' do
#     get 'get AWS servers' do
#       tags 'AWS Service Manager'
#       consumes 'application/json'
#       security [
#         { :Bearer => [] }
#       ]
#       parameter name: :adapter_id, in: :query, type: :string, required: false
#       parameter name: :region_id, in: :query, type: :string, required: false
#       parameter name: :vpc_id, in: :query, type: :string, required: false
#       parameter name: :subnet_id, in: :query, type: :string, required: false
#       parameter name: :search_text, in: :query, type: :string, required: false
#       parameter name: :tags, in: :query, type: :array, items: { type: 'string' }, required: false
#       parameter name: :per_page, in: :query, type: :integer, required: false, default: 10
#       parameter name: :page, in: :query, type: :integer, required: false, default: 1
#       response '404', 'report not found' do
#         run_test!
#       end
#     end
#   end

#   path '/aws/service_manager/volumes' do
#     get 'get AWS volumes' do
#       tags 'AWS Service Manager'
#       consumes 'application/json'
#       security [
#         { :Bearer => [] }
#       ]
#       parameter name: :adapter_id, in: :query, type: :string, required: false
#       parameter name: :region_id, in: :query, type: :string, required: false
#       parameter name: :state, in: :query, type: :string, required: false
#       parameter name: :encrypted, in: :query, type: :boolean, required: false
#       parameter name: :search_text, in: :query, type: :string, required: false
#       parameter name: :tags, in: :query, type: :array, required: false
#       parameter name: :per_page, in: :query, type: :integer, required: false, default: 10
#       parameter name: :page, in: :query, type: :integer, required: false, default: 1

#       response '404', 'report not found' do
#         run_test!
#       end
#     end
#   end

#   path '/aws/service_manager/load_balancers' do
#     get 'Get AWS Load Balancers' do
#       tags 'AWS Service Manager'
#       consumes 'application/json'
#       security [
#         { :Bearer => [] }
#       ]
#       parameter name: :adapter_id, in: :query, type: :string, required: false
#       parameter name: :region_id, in: :query, type: :string, required: false
#       parameter name: :vpc_id, in: :query, type: :string, required: false
#       parameter name: :state, in: :query, type: :string, required: false
#       parameter name: :search_text, in: :query, type: :string, required: false
#       parameter name: :tags, in: :query, type: :array, required: false
#       parameter name: :per_page, in: :query, type: :integer, required: false, default: 10
#       parameter name: :page, in: :query, type: :integer, required: false, default: 1

#       response '404', 'report not found' do
#         run_test!
#       end
#     end
#   end

#   path '/aws/service_manager/auto_scaling_groups' do
#     get 'Get AWS Auto Scaling Groups' do
#       tags 'AWS Service Manager'
#       consumes 'application/json'
#       security [
#         { :Bearer => [] }
#       ]

#       parameter name: :adapter_id, in: :query, type: :string, required: false
#       parameter name: :region_id, in: :query, type: :string, required: false
#       parameter name: :state, in: :query, type: :string, required: false
#       parameter name: :search_text, in: :query, type: :string, required: false
#       parameter name: :tags, in: :query, type: :array, required: false
#       parameter name: :per_page, in: :query, type: :integer, required: false, default: 10
#       parameter name: :page, in: :query, type: :integer, required: false, default: 1

#       response '404', 'report not found' do
#         run_test!
#       end
#     end
#   end

#   path '/aws/service_manager/elastic_ips' do
#     get 'Get AWS Elasptic Ips' do
#       tags 'AWS Service Manager'
#       consumes 'application/json'
#       security [
#         { :Bearer => [] }
#       ]

#       parameter name: :adapter_id, in: :query, type: :string, required: false
#       parameter name: :region_id, in: :query, type: :string, required: false
#       parameter name: :search_text, in: :query, type: :string, required: false
#       parameter name: :tags, in: :query, type: :array, required: false
#       parameter name: :per_page, in: :query, type: :integer, required: false, default: 10
#       parameter name: :page, in: :query, type: :integer, required: false, default: 1

#       response '404', 'report not found' do
#         run_test!
#       end
#     end
#   end

#   path '/aws/service_manager/network_interfaces' do
#     get 'Get AWS Network Interfaces' do
#       tags 'AWS Service Manager'
#       consumes 'application/json'
#       security [
#         { :Bearer => [] }
#       ]
#       parameter name: :adapter_id, in: :query, type: :string, required: false
#       parameter name: :region_id, in: :query, type: :string, required: false
#       parameter name: :vpc_id, in: :query, type: :string, required: false
#       parameter name: :state, in: :query, type: :string, required: false
#       parameter name: :search_text, in: :query, type: :string, required: false
#       parameter name: :tags, in: :query, type: :array, required: false
#       parameter name: :per_page, in: :query, type: :integer, required: false, default: 10
#       parameter name: :page, in: :query, type: :integer, required: false, default: 1
#       response '404', 'report not found' do
#         run_test!
#       end
#     end
#   end

#   path '/aws/service_manager/launch_configurations' do
#     get 'Get AWS Launch Configurations' do
#       tags 'AWS Service Manager'
#       consumes 'application/json'
#       security [
#         { :Bearer => [] }
#       ]
#       parameter name: :adapter_id, in: :query, type: :string, required: false
#       parameter name: :region_id, in: :query, type: :string, required: false
#       parameter name: :state, in: :query, type: :string, required: false
#       parameter name: :search_text, in: :query, type: :string, required: false
#       parameter name: :tags, in: :query, type: :array, required: false
#       parameter name: :per_page, in: :query, type: :integer, required: false, default: 10
#       parameter name: :page, in: :query, type: :integer, required: false, default: 1
#       response '404', 'report not found' do
#         run_test!
#       end
#     end
#   end

#   path '/aws/service_manager/key_pairs' do
#     get 'Get AWS Key Pairs' do
#       tags 'AWS Service Manager'
#       consumes 'application/json'
#       security [
#         { :Bearer => [] }
#       ]
#       parameter name: :adapter_name, in: :query, type: :string, required: false
#       parameter name: :region_name, in: :query, type: :string, required: false
#       parameter name: :name, in: :query, type: :string, required: false
#       parameter name: :tags, in: :query, type: :array, required: false
#       parameter name: :per_page, in: :query, type: :integer, required: false, default: 10
#       parameter name: :page, in: :query, type: :integer, required: false, default: 1

#       response '404', 'report not found' do
#         run_test!
#       end
#     end
#   end

#   path '/aws/service_manager/databases' do
#     get 'Get AWS Databases' do
#       tags 'AWS Service Manager'
#       consumes 'application/json'
#       security [
#         { :Bearer => [] }
#       ]
#       parameter name: :adapter_id, in: :query, type: :string, required: false
#       parameter name: :region_id, in: :query, type: :string, required: false
#       parameter name: :vpc_id, in: :query, type: :string, required: false
#       parameter name: :state, in: :query, type: :string, required: false
#       parameter name: :search_text, in: :query, type: :string, required: false
#       parameter name: :tags, in: :query, type: :array, required: false
#       parameter name: :per_page, in: :query, type: :integer, required: false, default: 10
#       parameter name: :page, in: :query, type: :integer, required: false, default: 1

#       response '404', 'report not found' do
#         run_test!
#       end
#     end
#   end

#   path '/aws/service_manager/storages' do
#     get 'Get AWS Storages' do
#       tags 'AWS Service Manager'
#       consumes 'application/json'
#       security [
#         { :Bearer => [] }
#       ]
#       parameter name: :adapter_name, in: :query, type: :string, required: false
#       parameter name: :region_name, in: :query, type: :string, required: false
#       parameter name: :name, in: :query, type: :string, required: false
#       parameter name: :tags, in: :query, type: :array, required: false
#       parameter name: :per_page, in: :query, type: :integer, required: false, default: 10
#       parameter name: :page, in: :query, type: :integer, required: false, default: 1

#       response '404', 'report not found' do
#         run_test!
#       end
#     end
#   end

#   path '/aws/service_manager/encryption_keys' do
#     get 'Get AWS Encryption Keys' do
#       tags 'AWS Service Manager'
#       consumes 'application/json'
#       security [
#         { :Bearer => [] }
#       ]
#       parameter name: :adapter_name, in: :query, type: :string, required: false
#       parameter name: :region_name, in: :query, type: :string, required: false
#       parameter name: :name, in: :query, type: :string, required: false
#       parameter name: :tags, in: :query, type: :array, required: false
#       parameter name: :per_page, in: :query, type: :integer, required: false, default: 10
#       parameter name: :page, in: :query, type: :integer, required: false, default: 1

#       response '404', 'report not found' do
#         run_test!
#       end
#     end
#   end


#   path '/aws/service_manager/encryption_keys/sync_encryption_keys' do
#     get 'sync encryption keys' do
#       tags 'AWS Service Manager'
#       consumes 'application/json'
#       security [
#         { :Bearer => [] }
#       ]
#       response '404', 'report not found' do
#         run_test!
#       end
#     end
#   end
# end
