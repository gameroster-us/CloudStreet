class GeneralSetting < ApplicationRecord
  include Authority::Abilities
  self.authorizer_name = "GeneralSettingAuthorizer"
  belongs_to :account
  # default_tenant_visibility field is used to determine if Default tenant can view sub-tenant data
  # validates_inclusion_of :ip_auto_increment_enabled, in: [true, false]
  validates_inclusion_of :naming_convention_enabled, in: [true, false]
  validates_format_of :email_domain,
    with: /\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}\z/ix,
    message: "Require a valid email domain",
    allow_nil: true,
    allow_blank: true
end
