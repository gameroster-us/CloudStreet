namespace :access_rights do
  desc 'add permission(cs_non_financial_dashboard_view,'\
       ' cs_non_financial_dashboard_view cs_environment_service_purge'\
       ' cs_service_edit cs_restricted_application_view'\
       ' cs_restricted_environment_view) to access rights'
  task create: :environment do
    CSLogger.info 'Creating access rights...'
    %w(cs_financial_dashboard_view
       cs_non_financial_dashboard_view cs_service_edit
       cs_environment_service_purge cs_restricted_environment_view
       cs_restricted_application_view cs_backup_configuration_manage
       cs_http_proxy_configuration_manage cs_smtp_configuration_manage
       cs_sso_configuration_manage cs_ssl_certificate_manage
       cs_dns_server_preferences_manage).each do |access_right|
      AccessRight.find_or_create_by(code: access_right)
    end
    CSLogger.info 'Created access rights!'
  end

  desc 'Update access rights for existing users'
  task update: :environment do
    # Manage access tab permissions
    CSLogger.info 'Creating Manage access permissions'
    access_right = AccessRight.find_by(code: 'cs_environment_edit')
    # Fethching user roles with cs_environment_edit permission
    user_role_ids = AccessRightsUserRoles
                      .where(access_right_id: access_right.id)
                      .map(&:user_role_id)
    access_right_ids = AccessRight.where(code: %w(cs_environment_service_purge
                                                  cs_service_edit)).map(&:id)
    # Excluding user role who has new permission
    user_role_ids.each do |user_role|
      access_right_ids.each do |ar|
        AccessRightsUserRoles.find_or_create_by(access_right_id: ar,
                                                user_role_id: user_role)
      end
    end
    CSLogger.info 'Created Manage permissions'

    CSLogger.info 'Creating dashboard permissions'
    user_roles = UserRole.joins(account: [organisation: :application_plan])
                         .where("application_plans.name = 'normal' AND "\
                                "user_roles.name = 'Administrator'")
    access_right = AccessRight
                   .find_by(code: 'cs_financial_dashboard_view')
    user_roles.each do |user_role|
      AccessRightsUserRoles.find_or_create_by(access_right_id: access_right
                                                                   .id,
                                              user_role_id: user_role.id)
    end
    CSLogger.info 'Created dashboard permissions'
  end

  desc 'Update event schedular and appliances rights for CloudStreetMarketplaceAMIAdmin'
  task update_CS_admin: :environment do
    all_rights = { right: [
      { code: 'cs_backup_configuration_manage', title: 'Backup Configuration' },
      { code: 'cs_http_proxy_configuration_manage', title: 'HTTP Proxy Configuration' },
      { code: 'cs_smtp_configuration_manage', title: 'SMTP Configuration' },
      { code: 'cs_sso_configuration_manage', title: 'SSO Configuration' },
      { code: 'cs_ssl_certificate_manage', title: 'SSL Configuration' },
      { code: 'cs_dns_server_preferences_manage', title: 'DNS Server Configuration'}]
    }

    # Create or find all rights
    all_rights[:right].each do|right|
      AccessRight.find_or_create_by(code: right[:code]) do |access_right|
        access_right.title=right[:title]
      end
    end

    # Access rights for User R
    UserRole.where(name: 'CloudStreetMarketplaceAMIAdmin').each do|role|
      all_rights[:right].each do|right|
        access_right = AccessRight.find_by_code(right[:code])
        # access_right.update_attribute(:title, right.title)
        AccessRightsUserRoles.find_or_create_by({ user_role_id: role.id, access_right_id: access_right.id })
      end
    end

    CSLogger.info 'Created access rights!'
  end

  task :create_new_rights_for_admin => [:create, :update, :update_CS_admin] do
    CSLogger.info "Created new access rights!"
  end

  desc 'Remove duplicate permissions for event scheduler(cs_event_scheduler_view and cs_event_scheduler_edit)'
  task remove_event_scheduler_rights: :environment do
    access_rights = AccessRight.where(code: ['cs_event_scheduler_view', 'cs_event_scheduler_edit'])
    arurs = AccessRightsUserRoles.where(access_right_id: access_rights.pluck(:id)).delete_all
    access_rights.delete_all
  end
  
  # Make sure to run populate_access_rights method from seed.rb file before running this rake task.
  desc 'Update default roles access'
  task update_default_roles_access: :environment do
    Organisation.all.each do |organisation|
      roles = organisation.application_plan.is_normal_plan? ? Settings.default_roles : Settings.viewer_role
      roles.each do |role|
        user_role=UserRole.find_by(:name=>role.first, organisation_id: organisation.id)
        next if user_role.blank?
        next if role.last.blank?
        exising_access_rights = user_role.rights.pluck(:code)
        new_default_access_rights = role.last - exising_access_rights
        rights=new_default_access_rights.collect do|code|
          AccessRight.find_by_code(code)
        end
        user_role.rights << rights.compact unless rights.blank?
      end
    end
  end

  desc 'Remove all Access rights of Basic Role'
  task remove_basic_role_access_rights: :environment do
    Organisation.all.each do |organisation|
      user_role = UserRole.find_by(name: "Basic", organisation_id: organisation.id)
      next if user_role.blank?
      user_role.rights.clear
      user_role.save(validate:false)
      CSLogger.info "===Removing Bacic role access rights for organisation #{organisation.name}"
    end
  end

end
