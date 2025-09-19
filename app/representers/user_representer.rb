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
  property :google_qr_uri, getter:  lambda { |args| get_google_qr_uri(args[:options][:current_account]) }
  property :mfa_enabled
  property :state, getter: lambda { |args| OrganisationUser.where(organisation_id: args[:options][:current_account].organisation_id, user_id: self.id).first.try(:state) }
  property :is_owner, getter: lambda { |args| self.own_organisation(args[:options][:current_account].organisation_id).try(:id).present? }
  property :created_at
  property :show_intro
  property :account,  getter: lambda { |args| args[:options][:current_account] }, class: Account, extend: AccountRepresenter
  property :rights_codes
  property :userrole
  property :user_preferences
  property :organisation, getter: lambda { |args| Organisation.find_by(id: args[:options][:current_account].organisation_id) }
  property :org_account, getter: ->(args) { args[:options][:current_account] }
  # CSas === step 2
  # property :account_preferences
  # property :trial_period_over
  property :user_type
  property :time_zone
  property :subdomain
  property :adapters_status, getter: lambda { |args| args[:options][:adapters_status] }
  property :last_activity
  property :override_tenant_currency
  property :reset_to_default_currency
  property :default_currency
  property :set_tenant_names, as: :organisation_tenants
  property :all_user_roles  # All roles of a user for users list
  property :hosted_zone
  property :is_global_admin, getter: lambda { |args|
    (args[:options][:current_account]).organisation.global_admin?
  }
  property :enable_welcome_popup
  property :adapters_group_status, getter: lambda { |args| args[:options][:adapters_group_status] }


  unless ENV['SAAS_ENV'] == false || ENV['SAAS_ENV'] == 'false'
    # CSas === step 2
    # link :self do |args|
    #   user_path(id) if args[:options][:current_user].can_read?(self)
    # end

    # link :remove do |args|
    #   user_path(id) if args[:options][:current_user].can_delete?(self)
    # end

    # link :edit do |args|
    #   user_path(id) if args[:options][:current_user].can_update?(self)
    # end
  end

  def rights_codes
    rights.pluck(:code).collect
  end

  def get_google_qr_uri(account)
    CurrentAccount.account = account
    #Here https://chart.googleapis.com/ has been depricated using the alternative for generating QR code
    google_qr_uri.gsub('https://chart.googleapis.com/chart?cht=qr&chl=', 'https://api.qrserver.com/v1/create-qr-code/?data=')
  end

  def userrole
    UserRole.joins(:user_roles_users).where(user_roles_users: {user_id: self.id,tenant_id: self.current_tenant}).pluck(:name)
  end

  def user_preferences
    return user_preference.preferences if user_preference.present?
    return {} if user_preference.blank?
  end

  def account_preferences
    # CSas === step 2
    # return account.user_preference.preferences if account.user_preference.present?
    # return {} if account.user_preference.blank?
  end

  def name
    self.attributes["name"]
  end

  def hosted_zone
    ENV["HOSTED_REGION"].present? ? CommonConstants::HOSTED_REGIONS[ENV["HOSTED_REGION"]] : CommonConstants::DEFAULT_REGIONS[Rails.env]
  end

  def set_tenant_names
    tenants.pluck(:name)
  end

end
