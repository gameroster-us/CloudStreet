class AccessAuthorizer < ApplicationAuthorizer
  def self.default(adjective, user, args={})
   true
  end
end
