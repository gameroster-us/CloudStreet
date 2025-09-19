# module Request
#   module AuthHelper
#     # Pass the @env along with your request
#     # eg: GET "/users", {}, @env
#     def http_login(user)
#       {
#         'HTTP_AUTHORIZATION' => user.jwt_auth_token
#       }
#     end

#     def stub_auth!
#       account ||= FactoryBot.create(:account, :with_user)
#       user_env ||= http_login(account.users.first)
#       [account, user_env]
#     end

#     def power_user
#       account ||= FactoryBot.create(:account, :with_power_user)
#       user_env ||= http_login(account.users.first)
#       account.users.first.user_roles.each do|role|
#         Settings.rights.each do|right|
#           AccessRight.find_or_create_by(code: right.code) do |access_right|
#             access_right.title=right.title
#           end
#           access_right = AccessRight.find_by_code(right.code)
#           access_right.update_attribute(:title, right.title)
#           AccessRightsUserRoles.find_or_create_by({ user_role_id: role.id, access_right_id: access_right.id })
#         end
#       end
#       [account, user_env]
#     end

#     def response_should_be
#       it "responds with 200" do
#         expect(response).to be_success
#       end
#     end
#   end
# end
