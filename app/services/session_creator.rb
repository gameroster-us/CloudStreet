class SessionCreator < CloudStreetService

  class SessionError < StandardError; end

  def self.get_organisation_list(username, password, host, params_page, &block)
    parent_organisation = Organisation.find_by_host(host)
    raise SessionError.new("Invalid host!") unless parent_organisation.present?

    child_org_ids = parent_organisation.child_organisations_ids_from_every_level

    raise SessionError.new("No organisation exists") unless child_org_ids.present?

    user = User.joins(:organisation_users).where("username = ? and user_type = ?", username, 'CloudStreet').where(organisations_users: {organisation_id: child_org_ids}).first

    user = User.joins(:organisation_users).where("email = ? and user_type = ?", username, 'CloudStreet').where(organisations_users: {organisation_id: child_org_ids}).first unless user

    raise SessionError.new(I18n.t('errors.auth.incorrect_username_password')) if user.blank?

    unless user.valid_for_authentication?
      raise SessionError.new(I18n.t('errors.auth.account_locked', time_left: seconds_to_hms((user.locked_at + User.unlock_in) - Time.now)))
    end

    unless user.authenticate(password)
      increment_failed_attempts(user)
      # lock user account when max failed attempt reached
      if user.failed_attempts >= User.maximum_attempts
        user.lock_access!
        raise SessionError.new(I18n.t('errors.auth.account_locked', time_left: seconds_to_hms((user.locked_at + User.unlock_in) - Time.now)))
      end

      # for giving warning when only 2 attempts are left
      if (User.maximum_attempts - user.failed_attempts) <= 2
        raise SessionError.new(I18n.t('errors.auth.account_lock_warning', attempt_left: User.maximum_attempts - user.failed_attempts))
      end

      raise SessionError.new(I18n.t('errors.auth.incorrect_username_password'))
    end

    organisations =  user.organisations.where(id: child_org_ids).order(:subdomain)

    organisations = organisations.where('organisations.subdomain ILIKE ?', "%#{params_page[:query]}%") if params_page[:query].present?

    organisations, total_records = data_pagination(organisations, params_page)

    status Status, :success, [organisations, total_records], &block

  rescue SessionError => e
    status Status, :validation_error, { message: e.message }, &block

  rescue Exception => e
    CSLogger.error e.backtrace
    CSLogger.error e.message
    status Status, :error, { message: e.message }, &block
  end

  def self.create(username, password, host, member_organisation_id = nil, mfa_code = nil, &block)
    # user = User.find_by_username(username)
    organisation = Organisation.find_by_host(host)

    if member_organisation_id.present?
      is_a_member = organisation.child_organisations_ids_from_every_level.include?(member_organisation_id)
      organisation = nil
      organisation = Organisation.where(id: member_organisation_id).first if is_a_member
    end

    if organisation.blank?
      status UserStatus, :error, I18n.t('errors.auth.organisation_unavailable'), &block
      return nil
    end

    user = User.joins(:organisation_users).where("username = ? and user_type = ?", username, 'CloudStreet').where(organisations_users: {organisation_id: organisation.id}).first if organisation

    user = User.joins(:organisation_users).where("email = ? and user_type = ?", username, 'CloudStreet').where(organisations_users: {organisation_id: organisation.id}).first unless user

    if user.blank?
      status UserStatus, :error, I18n.t('errors.auth.incorrect_username_password'), &block
      return nil
    end

    unless user.valid_for_authentication?
      status UserStatus, :error, I18n.t('errors.auth.account_locked', time_left: seconds_to_hms((user.locked_at + User.unlock_in) - Time.now)), &block
      return nil
    end

    unless user.authenticate(password)
      increment_failed_attempts(user)
      # lock user account when max failed attempt reached
      if user.failed_attempts >= User.maximum_attempts
        user.lock_access!
        status UserStatus, :error, I18n.t('errors.auth.account_locked', time_left: seconds_to_hms((user.locked_at + User.unlock_in) - Time.now)), &block
        return nil
      end

      # for giving warning when only 2 attempts are left
      if (User.maximum_attempts - user.failed_attempts) <= 2
        status UserStatus, :error, I18n.t('errors.auth.account_lock_warning', attempt_left: User.maximum_attempts - user.failed_attempts), &block
        return nil
      end

      status UserStatus, :error, I18n.t('errors.auth.incorrect_username_password'), &block
      return nil
    end
    organisation_user = organisation.get_organisation_user(user.id)
    if user.user_roles.count.eql?(1) && user.user_roles.first.name.eql?("Basic")
      status UserStatus, :error, I18n.t('errors.auth.insufficient_access_rights'), &block
    elsif organisation.try(:is_active).eql?(false)
      status UserStatus, :deactivated, nil, &block
      return nil
    elsif user.active? && organisation_user.active?
      user.subdomain = organisation.subdomain
      tenant_id = user.get_current_tenant_id(organisation)
      if tenant_id.nil?
        status UserStatus, :error, I18n.t('errors.auth.insufficient_access_rights'), &block
        return nil
      end
      if mfa_code.present?
        if user.google_authentic?(mfa_code)
          UserMfaSession.create(user)
        else
          increment_failed_attempts(user)
          # lock user account when max failed attempt reached
          if user.failed_attempts >= User.maximum_attempts
            user.lock_access!
            status UserStatus, :error, I18n.t('errors.auth.account_locked', time_left: seconds_to_hms((user.locked_at + User.unlock_in) - Time.now)), &block
            return nil
          end

          # for giving warning when only 2 attempts are left
          if (User.maximum_attempts - user.failed_attempts) <= 2
            status UserStatus, :error, I18n.t('errors.auth.account_lock_mfa_warning', attempt_left: User.maximum_attempts - user.failed_attempts), &block
            return nil
          end
          status UserStatus, :error, I18n.t('errors.auth.incorrect_mfa'), &block
          return nil
        end
      end
      session = Session.new(user, host)
      status UserStatus, :success, session, &block
      return session
    elsif user.state.eql?('disabled') || organisation_user.state.eql?('disabled')
      session = Session.new(user, host)
      status UserStatus, :disabled, session, &block
      return nil
    elsif user.unconfirmed_email.present? || organisation_user.invite_token.present?
      status UserStatus, :requires_confirmation, nil, &block
      return nil
    else
      status UserStatus, :error, I18n.t('errors.auth.incorrect_username_password'), &block
      return nil
    end
  end

  # increment failed_attempts count
  def self.increment_failed_attempts(user)
    user.increment :failed_attempts
    user.save(validate: false)
  end

  # Logic to convert seconds to hour:minute:second
  # "%02d:%02d:%02d" % [sec / 3600, sec / 60 % 60, sec % 60]
  def self.seconds_to_hms(sec)
    "%02d minutes %02d seconds" % [sec / 60 % 60, sec % 60]
  end

  def self.saml_login(email, attrs, organisation)
    SSOLog.info "email------#{email}"
    SSOLog.info "STEP 1 attrs in SessionCreator saml_login call------#{attrs}"
    sso_config = SsoConfig.find_or_initialize_by(account_id: organisation.account.id)
    if email.nil?
      SSOLog.error "====Email not fetched=="
      yield Status.error "Email not fetched."
      return nil
    end
    if attrs.empty?
      SSOLog.error "====SSO attrs are empty.!=="
      yield Status.error "No attributes fetched."
      return nil
    end
    if sso_config && sso_config.disable
      SSOLog.error "====SSO configuration is disabled.!=="
      yield Status.error "Single signon disabled."
      return nil
    end
    email = email.downcase
    # user = User.where("email = ? and user_type = ?", email, 'saml').first
    user = User.joins(:organisation_users).where("email = ? and user_type = ?", email, 'saml').where(organisations_users: {organisation_id: organisation.id}).first
    # user = User.find_by_email(email)
    #{"Name"=>["Pranav"], "Given Name"=>["Pranav"], "Role"=>nil, "E-Mail Address"=>["pranav@cloudstreet.com"]}
    attrs = map_attributes(attrs)

    if user.blank?
      user = create_saml_user(organisation, email, attrs)
      session = Session.new(user)
      yield Status.success(session) if block_given?
      return session
    end

    organisation_user = organisation.get_organisation_user(user.id)

    if user.active? && organisation_user.active? || organisation_user.state.eql?('pending')
      update_saml_user(organisation, user, attrs)
      session = Session.new(user)
      yield Status.success(session) if block_given?
      return session
    elsif user.state.eql?('disabled') || organisation_user.state.eql?('disabled')
      session = Session.new(user)
      yield Status.disabled(session) if block_given?
      return nil
    else
      yield Status.error if block_given?
      return nil
    end
  end

  def self.create_saml_user(organisation, email, attrs)
    subdomain = organisation.subdomain
    account = organisation.account
    pepper = SecureRandom.hex(8)
    encrypted_password = ::BCrypt::Password.create("#{pepper}", :cost => 10).to_s
    sso_config = SsoConfig.find_by(account_id: account.id)
    name = attrs[sso_config.name_attribute_key.downcase].blank? ? '' : attrs[sso_config.name_attribute_key.downcase][0]
    user = User.create_with(
      account_id: account.id,
      username: email,
      name: name,
      encrypted_password: encrypted_password,
      authentication_token: pepper,
      confirmed_at: Time.now,
      state: "active"
    ).find_or_create_by(email: email, user_type: 'saml')
    user.save!(validate: false)
    user.update(state: "active")
    organisation.users << user
    organisation_user = organisation.get_organisation_user(user.id)
    organisation_time_zone = organisation.general_setting.time_zone
    user.time_zone = { 'region' => organisation_time_zone["region"], 'user_time_zone' => organisation_time_zone["org_time_zone"]}
    SSOLog.info "STEP 2====Inside Create SAML User call for user ==#{user.try(:email)}===for Org==#{organisation.try(:subdomain)}="
    share_tenant_and_roles_to_saml_user(user, organisation, organisation_user, sso_config, attrs, action = 'CREATE')
    return user
  end

  def self.update_saml_user(organisation, user, attrs)
    subdomain = organisation.subdomain
    account = organisation.try(:account)
    pepper = SecureRandom.hex(8)
    encrypted_password = ::BCrypt::Password.create("#{pepper}", :cost => 10).to_s
    # user.username = attrs["givenname"][0]
    sso_config = SsoConfig.find_by(account_id: account.id)
    user.name = attrs[sso_config.name_attribute_key.downcase].blank? ? '' : attrs[sso_config.name_attribute_key.downcase][0]
    user.encrypted_password = encrypted_password if user.user_type == 'saml'
    user.authentication_token = pepper if user.user_type == 'saml'
    user.account_id = account.id unless account.blank?
    user.save(validate: false)
    organisation_user = organisation.get_organisation_user(user.id)
    SSOLog.info "STEP 3====Inside Update Existing SAML User call for user ==#{user.try(:email)}===for Org==#{organisation.try(:subdomain)}="
    share_tenant_and_roles_to_saml_user(user, organisation, organisation_user, sso_config, attrs, action = 'UPDATE')
    return user
  end

  def self.medianet_share_all_tenant(user, organisation, saml_roles)
    user.tenants.clear
    tenants = organisation.tenants
    UserRolesUser.where(user_id: user.id).destroy_all
    tenants.each do |tenant|
      tenant.users << user
      assign_role_to_saml_user(user, organisation, tenant, saml_roles)
    end
  end

  def self.set_default_tenant_for_saml_user(organisation, user, saml_roles)
    user.tenants.clear
    default_tenant = organisation.get_default_tenant
    default_tenant.users << user unless default_tenant.users.exists?(user.id)
    assign_role_to_saml_user(user, organisation, default_tenant, saml_roles)
  end

  def self.assign_role_to_saml_user(user, organisation, default_tenant, saml_roles)
    roles_ids_created = []
    if saml_roles.nil? || saml_roles.empty?
      user_role = organisation.roles.find_by_name(UserRole::BASIC)
      user_roles_user = UserRolesUser.find_or_create_by({user_id: user.id, user_role_id: user_role.id, tenant_id: default_tenant.id})
      roles_ids_created << user_roles_user.id
    else
      saml_str = "{"+saml_roles.map(&:downcase).join(',')+"}"
      roles = organisation.roles.where("sso_keywords && ?", "#{saml_str}")
      unless roles.empty?
        roles.each do |user_role|
          user_roles_user = UserRolesUser.find_or_create_by({user_id: user.id, user_role_id: user_role.id, tenant_id: default_tenant.id})
          roles_ids_created << user_roles_user.id
        end
      else
        user_role = organisation.roles.find_by_name(UserRole::BASIC)
        user_role = organisation.create_basic_role if user_role.blank?
        user_roles_user = UserRolesUser.find_or_create_by({user_id: user.id, user_role_id: user_role.id, tenant_id: default_tenant.id})
        roles_ids_created << user_roles_user.id
      end
    end
    UserRolesUser.where.not(id: roles_ids_created).where({user_id: user.id, tenant_id: default_tenant.id}).destroy_all
  end

  def self.share_tenant_and_roles_to_saml_user(user, organisation, organisation_user, sso_config, attrs, action)
    SSOLog.info "STEP 4====Inside share_tenant_and_roles_to_saml_user for user ==#{user.try(:email)}===for Org==#{organisation.try(:subdomain)}="
    tenant_attr_key = sso_config.sso_keyword_attribute_key.downcase
    role_attrs_key = sso_config.roles_attribute_key.downcase
    saml_roles = attrs[role_attrs_key]
    roles_ids_created = []
    if organisation.subdomain.eql?('medianet')
      medianet_share_all_tenant(user, organisation, saml_roles)
      return user
    end
    org_saml_user = OrganisationSamlUser.find_by(user_id: user.id, organisation_id: organisation.id, auto_assign_tenant: false, auto_assign_role: false)
    if org_saml_user.present?
      SSOLog.info "STEP 5====Check SSO User manual sharing option is ON for user==#{user.try(:email)}===for Org==#{organisation.try(:subdomain)}="
      return user
    elsif (attrs.key?(tenant_attr_key) && !attrs[tenant_attr_key].join.empty?) && (attrs.key?(role_attrs_key) && !attrs[role_attrs_key].join.empty?)
      # Get tenants from SSO conifg and map in CloudStreet.
      sso_keywords = attrs[tenant_attr_key]
      saml_sso_keywords = '{' + sso_keywords.map(&:downcase).join(',') + '}'
      tenants = organisation.tenants.where('sso_keywords && ?', saml_sso_keywords.to_s)
      # Get roles from SSO config and map in CloudStreet.
      saml_str = '{' + saml_roles.map(&:downcase).join(',') + '}'
      roles = organisation.roles.where('sso_keywords && ?', saml_str.to_s)
      if !tenants.blank? && !roles.blank?
         SSOLog.info "STEP 6====Assign matching tenants and roles AUTO for user==#{user.try(:email)}===for Org==#{organisation.try(:subdomain)}="
        organisation_user.update(state: 'active') unless organisation_user.state.eql?('active')
        user.tenants.clear
        tenants.each do |tenant|
          tenant.users << user unless tenant.users.exists?(user.id)
          share_roles_to_saml_user(user, roles, tenant, roles_ids_created)
        end
        saml_user = OrganisationSamlUser.find_by(organisation_id: organisation.id, user_id: user.id)
        if saml_user.present?
          SSOLog.info "STEP 8====Update SSO user config to true if user is present in AUTO Sharing ON==#{user.try(:email)}===for Org==#{organisation.try(:subdomain)}="
          saml_user.update(auto_assign_tenant: true, auto_assign_role: true)
        else
          SSOLog.info "STEP 9====Create SSO user config with true if user is NOT present in AUTO Sharing ON==#{user.try(:email)}===for Org==#{organisation.try(:subdomain)}="
          OrganisationSamlUser.create(organisation_id: organisation.id, user_id: user.id, auto_assign_tenant: true, auto_assign_role: true)
        end
      else
        SSOLog.info "STEP 10====IF Tenant and Role both Blank in AUTO Sharing ON==#{user.try(:email)}===for Org==#{organisation.try(:subdomain)}="
        create_or_update_saml_user_config(user, organisation_user, organisation, action)
      end
    else
      SSOLog.info "STEP 11====IF Tenant and Role Not matching in SAML Response in AUTO Sharing ON==#{user.try(:email)}===for Org==#{organisation.try(:subdomain)}="
      create_or_update_saml_user_config(user, organisation_user, organisation, action)
    end
    return user
  end

  def self.share_roles_to_saml_user(user, roles, tenant, roles_ids_created)
    SSOLog.info "STEP 7====Assign matching roles AUTO for user==#{user.try(:email)}===="
    unless roles.empty?
      roles.each do |user_role|
        user_roles_user = UserRolesUser.find_or_create_by({ user_id: user.id, user_role_id: user_role.id, tenant_id: tenant.id })
        roles_ids_created << user_roles_user.id
      end
    end
    UserRolesUser.where.not(id: roles_ids_created).where({ user_id: user.id, tenant_id: tenant.id }).destroy_all
  end

  def self.create_or_update_saml_user_config(user, organisation_user, organisation, action)
    organisation_user.update(state: 'pending') unless organisation_user.state.eql?('pending')
    user.tenants.clear
    saml_user = OrganisationSamlUser.find_by(organisation_id: organisation.id, user_id: user.id)
    if saml_user.present?
      saml_user.update(auto_assign_tenant: true, auto_assign_role: true)
    else
      OrganisationSamlUser.create(organisation_id: organisation.id, user_id: user.id, auto_assign_tenant: true, auto_assign_role: true)
    end
  end

  def self.map_attributes(attrs)
    attrs = attrs.to_h.map do |k, v|
      if k == 'Name' || k == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name" || k == "urn:mace:dir:attribute-def:displayName"
        {'name' => v}
      elsif k == 'Given Name' || k == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname" || k == "urn:mace:dir:attribute-def:givenName"
        {'givenname' => v}
      elsif k == 'Role' || k == "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
        {'role' => v}
      elsif k == 'E-Mail Address' || k == "urn:mace:dir:attribute-def:mail"
        {'email_address' => (v.map(&:downcase) rescue [] )}
      else
        {k.downcase => v}
      end
    end.reduce({}, :merge)
    attrs
  end
end
SessionCreator.send(:include, MarketplaceSessionCreator) if ENV['SAAS_ENV'] == false || ENV['SAAS_ENV'] == 'false'
