# Creating child organisation
class ChildOrganisation::Organisation::Creator < CloudStreetService
  def self.create_org_with_user(parent_organisation, current_user, params, &block)
    applicationplan = ApplicationPlan.get(params[:signup_as])
    params['organisation_attributes'].merge!(application_plan_id: applicationplan.id, trial_period_days: applicationplan.trial_period_days, name: params[:subdomain], subdomain: params[:subdomain], report_profile_id: params[:report_profile_id])
    organisation = Organisation.new(params['organisation_attributes'])
    ActiveRecord::Base.transaction do
      organisation&.subdomain&.downcase! if organisation&.subdomain
      organisation.is_active = false
      organisation.parent_id = parent_organisation.id
      organisation.organisation_purpose = params['organisation_purpose']
      organisation.child_organisation_enable = true if params['organisation_purpose'].present? && params['organisation_purpose'].eql?('reseller')
      organisation.owner_type = params[:ownerType].to_sym if params[:ownerType].present?
      organisation.save!
      if organisation.present?
        organisation.update_report_profile
        organisation.create_default_organisation_brand
      end
      account = organisation.create_account(synchronization_setting_attributes: {}, accountable_objects: 30, name: SecureRandom.uuid)
      # with new user
      if params['is_new_user']
        create_new_user_for_org(applicationplan, params, account, organisation)
      else
        # with existing user
        set_existing_user_to_org(applicationplan, params, account, organisation, current_user)
      end
    end
    if organisation.persisted?
      organisation.update_mongoid_yml
      create_service_group_athena_table(organisation)
      ReportProfile::Helper.create_reseller_report_profiles(organisation) if organisation.organisation_purpose.eql?('reseller')
    end
    status Status, :success, organisation, &block
    return [true, organisation]
  rescue ActiveRecord::RecordInvalid => e
    status Status, :validation_error, e.record.errors.to_hash, &block
    return [false, e.record.errors.to_hash]
  end

  def self.org_with_new_user_as_owner(params, account, organisation)
    user = save_user_data(params, true, account)
    organisation.update(user_id: user.id)
    @invite_token = organisation.invite_user(user)
    
    # Activating organisation
    organisation.mark_as_reactive  
    user
  end

  def self.create_new_user_for_org(applicationplan, params, account, organisation)
    user = org_with_new_user_as_owner(params, account, organisation)
    organisation_post_creation(organisation, params, user, account, applicationplan)

    # setting time zone for new user
    organisation_time_zone = organisation.general_setting.time_zone
    user.time_zone = { 'region' => organisation_time_zone['region'], 'user_time_zone' => organisation_time_zone['org_time_zone'] }
    user.save!

    # user in invited state
    user.invite!

    # sending invite mail
    Notification.get_notifier.invite_group_user(user.id, @invite_token, params['child_host'])
    Notification.get_notifier.invite_group_user(current_user.id, @owner_invite_token, params['child_host']) if params['is_owner']
    user
  end

  def self.set_existing_user_to_org(applicationplan, params, account, organisation, current_user)
    user = User.find_by(id: params['existing_user_id'])
    organisation.update(user_id: user.id)

    @invite_token = organisation.invite_user(user) unless user.id.eql?(current_user.id) && params['is_owner']

    organisation_post_creation(organisation, params, user, account, applicationplan)

    # Activating organisation
    organisation.mark_as_reactive

    # sending notification mail

    Notification.get_notifier.invite_group_user(user.id, @invite_token, params['child_host'])
  end

  def self.save_user_data(params, is_admin, account)
    password = UserCreator.random_password
    user = User.new(
      name: SecureRandom.uuid,
      unconfirmed_email: params['email'],
      password: password,
      password_confirmation: password,
      confirmation_token: SecureRandom.hex(8),
      authentication_token: SecureRandom.hex(8),
      username: SecureRandom.uuid,
      account_id: account.id,
      is_admin: is_admin
    )
    user.save!
    user
  end

  def self.organisation_post_creation(organisation, params, user, account, applicationplan)
    organisation.create_default_tenant
    default_tenant = organisation.get_default_tenant
    #For Creating Child Organisation we need to Assign Report Profile id to Default Tenant
    default_tenant.update(report_profile_id: organisation.report_profile_id)
    default_tenant.users << user
    account.post_create_initializers
    default_role = applicationplan.is_normal_plan? ? organisation.roles.find_by_name(UserRole::ADMIN) : organisation.roles.find_by_name('Viewer')
    organisation.users.each do |org_user|
      UserRolesUser.find_or_create_by(user_id: org_user.id, user_role_id: default_role.id, tenant_id: default_tenant.id)
    end
    user.create_user_preference(sync_guidelines: true)
  end

  #creating service groups athena tables
  def self.create_service_group_athena_table(organisation)
    AthenaTableSchemaUpdateWorker.perform_action(organisation.organisation_identifier, %w[AWS Azure GCP])
  end
end
