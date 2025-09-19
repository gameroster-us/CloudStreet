class AccountAuthorizer < ApplicationAuthorizer
  def readable_by?(user)
    user.account_id == resource.id
  end

  def updatable_by?(user)
    access = false
    user.groups.each { |g| access = true if g.has_role? :account_owner, resource }

    access
  end

  def deletable_by?(user)
    access = false
    user.groups.each { |g| access = true if g.has_role? :account_owner, resource }

    access
  end

  def self.accessible_by?(user)
    user.is_permission_granted?("cs_settings_financial_view")
  end
end
