class SnapshotAuthorizer < ApplicationAuthorizer
  def self.default(adjective, user,args={})
    false
  end

  def self.readable_by?(user,args={})
    true
  end

  def self.updatable_by?(user, args={})
    true
  end

  def self.creatable_by?(user,args={})
    user.is_permission_granted?("cs_env_snapshot_create")
  end

  def self.deletable_by?(user)
    user.is_permission_granted?("cs_env_snapshot_delete")
  end

  def readable_by?(user)
    user.account_id == resource.account_id
  end
end
