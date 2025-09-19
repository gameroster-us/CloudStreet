class OrganisationBrandAuthorizer < ApplicationAuthorizer
  def self.default(adjective, user,args={})
    false
  end

  def self.readable_by?(user,args={})
    user.is_permission_granted?('cs_organisation_brand_view')
  end

  def self.updatable_by?(user,args={})
    user.is_permission_granted?('cs_organisation_brand_edit')
  end

  # Not yet Implemented right not added except for the apis
  # def self.creatable_by?(user,args={})
  #   user.is_permission_granted?('cs_organisation_brand_create')
  # end

  # def self.deletable_by?(user)
  #   user.is_permission_granted?('cs_organisation_brand_delete')
  # end
end
