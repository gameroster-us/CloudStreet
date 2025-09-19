class OsAuthorizer < ApplicationAuthorizer
	#AMIAuthorizor
  def self.default(adjective, user, args={})
   false
  end

  def self.readable_by?(user)
    user.is_permission_granted?("cs_ami_view")
  end

  def self.creatable_by?(user)
    user.is_permission_granted?("cs_org_os_add")
  end

  def self.updatable_by?(user)
    user.is_permission_granted?("cs_org_os_edit")
  end

  def self.deletable_by?(user)
    user.is_permission_granted?("cs_org_os_remove")
  end

  def self.manageable_by?(user)
    true
  end
end
