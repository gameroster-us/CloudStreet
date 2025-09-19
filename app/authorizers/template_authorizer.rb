class TemplateAuthorizer < ApplicationAuthorizer
  def self.default(adjective, user,args={})
    false
  end
  
  def self.readable_by?(user,args={})
    user.is_permission_granted?("cs_template_view")
  end

  def self.creatable_by?(user,args={})    
    user.is_permission_granted?("cs_template_create")
  end

  def self.updatable_by?(user,args={})
    user.is_permission_granted?("cs_template_edit")
  end

  def self.deletable_by?(user,args={})
    user.is_permission_granted?("cs_template_delete")
  end
  
  def self.provisionable_by?(user,args={})
    user.is_permission_granted?("cs_template_provision")
  end

  def self.manageable_by?(user)
    user.is_permission_granted?('cs_settings_sync_manage')
  end

  def readable_by?(user)
    flag = true
    if (user.account_id == resource.account_id) || (resource.generic_type? && user.account_id == resource.updator.account_id)
      if resource.created_by == user.id || resource.shared_with.blank? || resource.shared_with.include?(user.id) || !(resource.shared_with & user.user_role_ids).empty?
        flag = true
      else
        flag = false
      end
    else
      flag = false
    end
    flag
  end

  def creatable_by?(user)
    true
  end

  def updatable_by?(user)
    # TODO: Generic Template
    # For Generic template, we are not keeping account_id but we have `updator` by which we can find account
    account_id = resource.generic_type? ? resource.updator.account_id : resource.account_id
    user.account_id == account_id
  end

  def deletable_by?(user)
    account_id = resource.generic_type? ? resource.updator.account_id : resource.account_id
    user.account_id == account_id
  end

  def provisionable_by?(user)
    if resource.generic_type?
      user.is_permission_granted?("cs_template_provision")
    else
      user.account_id == resource.account_id
    end
  end

  def accessible_by?(user, args={})
    true
  end

  def self.accessible_by?(user, args={})
    true
  end
end
