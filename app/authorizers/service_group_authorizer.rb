class ServiceGroupAuthorizer < ApplicationAuthorizer
  def self.default(adjective, user, args = {})
    false
  end
  
  def self.readable_by?(user, args = {})
    user.is_permission_granted?('cs_service_group_view')
  end

  def self.updatable_by?(user, args = {})
    user.is_permission_granted?('cs_service_group_edit')
  end

  def self.creatable_by?(user, args = {})
    user.is_permission_granted?('cs_service_group_create')
  end

  def self.deletable_by?(user)
    user.is_permission_granted?('cs_service_group_delete')
  end
end
