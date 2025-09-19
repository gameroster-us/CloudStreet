class RdsConfigurationAuthorizer < ApplicationAuthorizer
 def self.default(adjective, user,args={})
    false
  end
  
  def self.readable_by?(user,args={})
    user.is_permission_granted?("cs_rds_configuration_view")
  end

  def self.creatable_by?(user,args={})
    user.is_permission_granted?("cs_rds_configuration_manage") 
  end

  def self.editable_by?(user,args={})
    user.is_permission_granted?("cs_rds_configuration_manage")    
  end

  def self.updatable_by?(user,args={})
    user.is_permission_granted?("cs_rds_configuration_manage")
  end

  def self.deletable_by?(user,args={})
    user.is_permission_granted?("cs_rds_configuration_manage") 
  end
  
  def readable_by?(user)
    user.account_id == resource.account_id
  end

  def editable_by?(user)
    user.account_id == resource.account_id
  end

  def creatable_by?(user)
    user.account_id == resource.account_id
  end

  def updatable_by?(user)
    user.account_id == resource.account_id
  end

  def deletable_by?(user)
    user.account_id == resource.account_id
  end
  
end
