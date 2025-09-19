# frozen_string_literal: false

module ManageUsers
  # Renders user attributes for manage user page
  module UserRepresenter
    include Roar::JSON
    include Roar::Hypermedia
    include Roar::JSON::HAL
    include MarketplaceUserRepresenter if ENV['SAAS_ENV'] == false || ENV['SAAS_ENV'] == 'false'

    property :id
    property :username
    property :email
    property :unconfirmed_email
    property :name
    property :state, getter: (lambda do |args|
      OrganisationUser.where(organisation_id: args[:options][:current_account].organisation_id, user_id: id)
                      .first.try(:state)
    end)
    property :is_owner, getter: ->(args) { own_organisation(args[:options][:current_account].organisation_id).try(:id).present? }
    property :created_at
    property :show_intro
    property :rights_codes
    property :userrole
    property :user_preferences
    property :organisation, getter: ->(args) { Organisation.find_by(id: args[:options][:current_account].organisation_id) }
    property :org_account, getter: ->(args) { args[:options][:current_account] }
    property :user_type
    property :time_zone
    property :subdomain
    property :adapters_status, getter: ->(args) { args[:options][:adapters_status] }
    property :last_activity
    property :override_tenant_currency
    property :reset_to_default_currency
    property :default_currency
    property :fetch_organisation_tenants, as: :organisation_tenants
    property :all_user_roles
    property :hosted_zone

    def rights_codes
      rights.pluck(:code)
    end

    def userrole
      UserRole.joins(:user_roles_users).where(user_roles_users: { user_id: id, tenant_id: current_tenant }).pluck(:name)
    end

    def user_preferences
      user_preference.try(:preferences) || {}
    end

    def hosted_zone
      CommonConstants::HOSTED_REGIONS[ENV['HOSTED_REGION']] || CommonConstants::DEFAULT_REGIONS[Rails.env]
    end

    def fetch_organisation_tenants
      {
        tenants: organisation_tenants
      }
    end
  end
end
