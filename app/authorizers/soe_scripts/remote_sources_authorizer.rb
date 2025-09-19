class SoeScripts::RemoteSourcesAuthorizer < ApplicationAuthorizer
 def self.default(adjective, user,args={})
    false
  end
  
  def self.readable_by?(user,args={})
    user.is_permission_granted?("cs_ami_soe_scripts")
  end

  def self.creatable_by?(user,args={})
    user.is_permission_granted?("cs_ami_soe_scripts")
  end

  def self.updatable_by?(user,args={})
    user.is_permission_granted?("cs_ami_soe_scripts")
  end

  def self.deletable_by?(user,args={})
    user.is_permission_granted?("cs_ami_soe_scripts")
  end

  def readable_by?(user)
    user.is_permission_granted?("cs_ami_soe_scripts")
  end

  def creatable_by?(user)
    user.is_permission_granted?("cs_ami_soe_scripts")
  end

  def updatable_by?(user)
    user.is_permission_granted?("cs_ami_soe_scripts")
  end

  def deletable_by?(user)
    user.is_permission_granted?("cs_ami_soe_scripts")
  end
end
