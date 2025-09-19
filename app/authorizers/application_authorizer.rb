# Other authorizers should subclass this one
class ApplicationAuthorizer < Authority::Authorizer
  # Any class method from Authority::Authorizer that isn't overridden
  # will call its authorizer's default method.
  #
  # @param [Symbol] adjective; example: `:creatable`
  # @param [Object] user - whatever represents the current user in your app
  # @return [Boolean]
  # TODO: make sure we add checks for account_admin soon, as well
  def self.default(adjective, user, args)
    if adjective == :creatable
      account = Account.find(args[:account_id])
      has_access_through_group(user, account)
    else
      false
    end
  end

protected

  def self.has_access_through_group(user, account, roles=[:account_owner, :account_admin])
    access = false
    user.groups.each { |g| access = true if has_access(g, account, roles) }

    access
  end

  def self.has_access(entity, account, roles)
    access = false
    roles.each { |r| access = true if entity.has_role?(r, account) }

    access
  end

  def self.user_has_permissions_to_access(user,access_right)
    # access=false
    # user.user_roles.each do|role|
    #   if role.rights.pluck(:code).include? access_right
    #     access=true
    #     break
    #   end
    # end
    # access
    true
  end
end
