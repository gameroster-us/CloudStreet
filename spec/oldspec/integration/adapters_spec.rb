# frozen_string_literal: true

# describe 'AWS Adapters' do
#   path '/aws/adapters' do
#     get 'get AWS adapters ' do
#       tags 'AWS adapters'
#       security [
#         { :Bearer => [] }
#       ]
#       response '404', 'Adapter not found' do
#         run_test!
#       end
#       response '500', 'someting went wrong' do
#         run_test!
#       end
#     end
#   end

#   path '/aws/adapters/destroy_all_adapters' do
#     delete 'Delete All Adapters' do
#       tags 'Adapters'
#       security [
#         { :Bearer => [] }
#       ]
#       response '404', 'Adapter not found' do
#         run_test!
#       end
#       response '500', 'someting went wrong' do
#         run_test!
#       end
#     end
#   end

#   path '/aws/adapters/{id}/destroy' do
#     delete 'delete AWS Aadapter' do
#       tags 'AWS adapters'
#       security [
#         { :Bearer => [] }
#       ]
#       parameter name: :id, in: :path, type: :string, required: true
#       response '404', 'Adapter not found' do
#         run_test!
#       end
#       response '500', 'someting went wrong' do
#         run_test!
#       end
#     end
#   end
# end
