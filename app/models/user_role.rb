class UserRole < ApplicationRecord
  include Authority::Abilities
  prepend MarketplaceUserRole if ENV['SAAS_ENV'] == false || ENV['SAAS_ENV'] == 'false'
  ADMIN="Administrator"
  BASIC="Basic"

  self.authorizer_name = "UserRoleAuthorizer"
  has_and_belongs_to_many :rights, :class_name=> 'AccessRight'
  belongs_to :organisation
  has_and_belongs_to_many :users
  has_many :user_roles_users
  has_many :integration_user_roles, dependent: :destroy
  has_many :user_roles, through: :integration_user_roles
  validates_uniqueness_of :name, :scope => :organisation_id
  validates_presence_of :name
  validates :name, presence: true, format: { with: /\A[a-zA-Z0-9\s\-_]+\z/, message: "should contain only alphanumeric, space and special characters(- _)" }
  # validates_uniqueness_of :name, case_sensitive: false

  scope :by_organisation, ->(organisation_id){where(organisation_id: organisation_id)}
  scope :user_role, ->(user_id){where(id: user_id)}
  scope :without_mira_roles, -> { where(mira: false) }

  attr_accessor :org_active_users_count

  def number_of_users
    org_active_users_count || 0
  end

  def set_active_user_count(active_user_ids)
    self.org_active_users_count = user_roles_users.where(user_id: active_user_ids).pluck(:user_id).uniq.count
  end

  def has_access(right)
    AccessRightsUserRoles.where(access_right_id: right.id, user_role_id: self.id).present?
  end

  def reset_access(right_ids = [])
    unless organisation.global_admin?
      global_right_ids = AccessRight.global_admin_rights.ids
      right_ids.reject! { |id| global_right_ids.include?(id) }
    end

    if mira?
      mira_access_right_ids = AccessRight.mira_rights
      right_ids.reject! { |id| mira_access_right_ids.include?(id) }
      mira_default_right_ids = AccessRight.mira_default_right.try(:ids)
      # Check if the default MIRA access right ID exists and is not already included in the user role rights, then push it to the rights array.
      right_ids << (mira_default_right_ids - right_ids) if mira_default_right_ids.any? && (mira_default_right_ids - right_ids).any?                                
      right_ids.flatten!
    end

    self.rights = []
    arurs = []
    right_ids.each do |right_id|
      arurs << {
        access_right_id: right_id,
        user_role_id: id
      }
    end
    AccessRightsUserRoles.import(arurs)
  end

end
