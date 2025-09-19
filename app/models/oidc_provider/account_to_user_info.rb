class OIDCProvider::AccountToUserInfo
  def call(user, scope_names)
    openid_supported_scope = ['openid','profile', 'email']
    scopes = scope_names.map { |name| openid_supported_scope.detect { |scope| scope == name } }.compact
    OpenIDConnect::ResponseObject::UserInfo.new(sub: user.id).tap do |user_info|
      scopes.each do |scope|
        if scope.eql?("email")
          user_info.email = user.email
        end
        if scope.eql?("profile")
          user_info.name = user.name
          user_info.given_name = user.name
          user_info.preferred_username = user.username
        end
      end
    end
  end
end
