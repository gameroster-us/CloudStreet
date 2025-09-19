class UserSearcher < CloudStreetService

  def self.search(&block)
    users = User.all

    status UserStatus, :success, users, &block
    return
  end

  def self.find(user_id, &block)
    user = User.find(user_id)

    status UserStatus, :success, user, &block
  end

  def self.find_by_invite_token(invite_token, &block)
    user = User.find_by_invite_token(invite_token)

    if user.nil? || invite_token.to_s == ''
      status UserStatus, :no_invite_token_found, nil, &block
    else
      status UserStatus, :success, user, &block
    end
  end

  def self.find_by_role(organisation, role_id, page_params, &block)
    role = fetch UserRole, role_id
    available_user_ids = role.user_roles_users.pluck(:user_id).uniq
    users = User.by_organisation(organisation.id).active.where(id: available_user_ids)

    users, total_records = apply_pagination(users, page_params)

    status Status, :success, [users, total_records], &block
    return users
  end

  def self.search_saml_settings_for_user(organisation, user_id, &block)
    saml_settings_user = OrganisationSamlUser.find_by(user_id: user_id, organisation_id: organisation.id)
    status Status, :success, saml_settings_user, &block
  end

  def self.search_organisation_users_not_in_role(organisation, role_id, &block)
    role = fetch UserRole, role_id
    available_user_ids = role.user_roles_users.pluck(:user_id).uniq
    users = User.by_organisation(organisation.id).active.where.not(id: available_user_ids)
    status Status, :success, users, &block
    return users
  end

  def self.search_organisation_users(organisation, current_tenant, user_params, &block)
    users = organisation.users
    users = selected_users(organisation, current_tenant, user_params, users) if users.present?
    users, total_records = apply_pagination(users, user_params)
    users = filter_user_last_activity_and_tenants(users, organisation, current_tenant)
    status Status, :success, [users, total_records], &block
  end

  def self.search_for_suggesion(organisation, user, params, &block)
    tenant = Tenant.find(params[:tenant_id])
    tenant_user_ids = tenant.users.pluck(:id)
    manual_saml_users_ids = OrganisationSamlUser.where(organisation_id: organisation.id, auto_assign_tenant: false, auto_assign_role: false).pluck(:user_id)
    org_users = organisation.users.where.not(id: tenant_user_ids)
    users = org_users.where.not(user_type: "saml").where("username LIKE ? OR email LIKE ? OR unconfirmed_email LIKE ?", "%#{params[:query]}%", "%#{params[:query]}%", "%#{params[:query]}%").or(org_users.where(id: manual_saml_users_ids, user_type: "saml").where("username LIKE ? OR email LIKE ? OR unconfirmed_email LIKE ?", "%#{params[:query]}%", "%#{params[:query]}%", "%#{params[:query]}%"))
    status Status, :success, users, &block
  end

  def self.is_processed_adapter_present(tenant)
    adapters_status = { AWS: false, Azure: false, GCP: false, AzureCsp: false, VmWare: false }

    billing_adapters = tenant.adapters.billing_adapters
    billing_adapter_ids = billing_adapters.ids
    # Vmware only has normal adapters no billing adapters
    vmware_adapters = tenant.adapters.vm_ware_adapter

    CurrentAccount.client_db = tenant.organisation.parent_id.nil? ? tenant.organisation.account : tenant.organisation.root_parent.account
    other_month_file_info_status = FileInfo.by_adapters(billing_adapter_ids).not.where(month: Date.today.strftime("%Y-%m"))
    current_month_file_info_status = FileInfo.by_adapters(billing_adapter_ids).where(month: Date.today.strftime("%Y-%m"))
    billing_adapters.each do |adapter|
      adapter_type = adapter.data&.dig('azure_account_type').eql?('csp') ? 'AzureCsp'.to_sym : adapter.type.split('::').last.to_sym
      next if adapters_status[adapter_type] == true

      other_month_status = other_month_file_info_status.where(adapter_id: adapter.id).pluck(:status).uniq
      current_month_status = current_month_file_info_status.where(adapter_id: adapter.id).pluck(:status).uniq
      adapters_status[adapter_type] = (other_month_status.include?('success') || current_month_status.include?('progress'))
    end
    adapters_status[:VmWare] = vmware_adapters.pluck("data -> 'report_status'").compact.any?
    adapters_status
  end

  def self.get_adapters_group_status(account, tenant)
    groups_count = { groups_count: 0 }
    adapters_group_status = {
      AWS: groups_count.dup,
      Azure: groups_count.dup,
      GCP: groups_count.dup
    }
    adapters_group_status[:AWS][:groups_count] = get_adapters_group_count(account, tenant, 'AWS')
    adapters_group_status[:Azure][:groups_count] = get_adapters_group_count(account, tenant, 'Azure')
    adapters_group_status[:GCP][:groups_count] = get_adapters_group_count(account, tenant, 'GCP')
    adapters_group_status
  end

  def self.get_adapters_group_count(account, tenant, provider)
    groups_count = ServiceGroup.where(account_id: account.id, tenant_id: tenant.id, provider_type: provider).count
    shared_groups_count = tenant.service_groups.where(provider_type: provider).count
    groups_count + shared_groups_count
  end

  def self.get_adapters_status(account, tenant, **options)
    adapters_status = zero_adapter_response
    adapters = tenant.present? && tenant.is_default ? account.organisation.adapters.available : tenant.try(:adapters)
    return adapters_status if adapters.nil? || adapters.empty?

    aws_active_adapters   = adapters.try(:aws_adapter)
    azure_active_adapters = adapters.try(:azure_adapter)
    gcp_active_adapters   = adapters.try(:gcp_adapter)
    vmware_active_adapters   = adapters.try(:vm_ware_adapter).try(:active_adapters)

    current_account = account.organisation.child_organisation? ? account.organisation.parent_organisation.account : account
    CurrentAccount.client_db = current_account

    adapters_status = aws_adapter_status(tenant, adapters_status) unless aws_active_adapters.blank?
    adapters_status = azure_adapter_status(tenant, adapters_status, options) unless azure_active_adapters.blank?
    adapters_status = gcp_adapter_status(tenant, adapters_status) unless gcp_active_adapters.blank?
    adapters_status = vm_ware_adapter_status(tenant, adapters_status, vmware_active_adapters) unless vmware_active_adapters.blank?
    adapters_status
  end

  def self.zero_adapter_response
    default_res = {
      is_billing_adapter_present: false,
      is_normal_adapter_present: false,
      is_report_config_present: false,
      is_consolidated: false,
      data_in_progress: false
    }
    { AWS: default_res.dup, Azure: default_res.dup, GCP: default_res.dup,
      VmWare: { is_adapter_present: false, data_in_progress: false } }
  end

  def self.vm_ware_adapter_status(tenant, adapters_status, vmware_active_adapters)
    current_vm_ware_adapter = get_or_set_vm_ware_default_adapter(tenant: tenant, active_adapters: vmware_active_adapters)
    status = { is_adapter_present: current_vm_ware_adapter.present?, data_in_progress: false }
    if current_vm_ware_adapter
      status[:data_in_progress] =  !current_vm_ware_adapter.report_status
      status[:last_vdc_sync_at] = current_vm_ware_adapter.data['last_vdc_sync_at']
      status[:rate_card_created_at] = current_vm_ware_adapter.data['rate_card_created_at']
    end
    adapters_status[:VmWare] = status
    adapters_status
  end

  def self.get_or_set_vm_ware_default_adapter(tenant:, active_adapters:)
    current_adapter = tenant.current_vm_ware_adapter
    return current_adapter if current_adapter.present?

    return nil if active_adapters.blank?

    tenant.set_default_vm_ware_adapter(active_adapters.first.id)
    tenant.current_vm_ware_adapter
  end

  def self.aws_adapter_status(tenant, adapters_status)
    aws_billing_adap = Adapter.find_by_id(tenant.current_billing_adapter_id)
    is_aws_normal_adp_exist = tenant.adapters.aws_normal_active_adapters.exists? rescue false

    adapters_status[:AWS][:is_billing_adapter_present] = true if aws_billing_adap.try(:adapter_purpose) == 'billing' || ReportConfiguration.where(adapter_id: aws_billing_adap.try(:id)).exists?
    adapters_status[:AWS][:is_normal_adapter_present] = is_aws_normal_adp_exist
    adapters_status[:AWS][:is_report_config_present] = ReportConfiguration.where(adapter_id: aws_billing_adap.try(:id)).exists?
    adapters_status[:AWS][:data_in_progress] = adapter_file_info_response(aws_billing_adap.try(:id))
    adapters_status
  end

  def self.azure_adapter_status(tenant, adapters_status, options)
    azure_billing_adap = Adapter.find_by_id(tenant.current_azure_billing_adapter_id)
    is_azure_normal_adp_exist = tenant.adapters.azure_normal_active_adapters.exists? rescue false
    is_total_selected = tenant.azure_tenant_billing_adapter.try(:is_total_selected).present?
    if is_total_selected
      adapters_status[:Azure][:is_billing_adapter_present] = true
      adapters_status[:Azure][:is_report_config_present] = true
    else
      adapters_status[:Azure][:is_billing_adapter_present] = true if azure_billing_adap.try(:adapter_purpose) == 'billing' || (AzureExportConfiguration.where(adapter_id: azure_billing_adap.try(:id)).exists? || (azure_billing_adap.present? && azure_billing_adap['data']['azure_account_type'].eql?('ea')) || (azure_billing_adap.present? && azure_billing_adap['data']['azure_account_type'].eql?('csp')) )
      if AzureExportConfiguration.where(adapter_id: azure_billing_adap.try(:id)).exists? || (azure_billing_adap.present? && azure_billing_adap['data']['azure_account_type'].eql?('ea')) || (azure_billing_adap.present? && azure_billing_adap['data']['azure_account_type'].eql?('csp'))
        adapters_status[:Azure][:is_report_config_present] = true
      end
    end
    adapters_status[:Azure][:is_normal_adapter_present] = is_azure_normal_adp_exist
    adapters_status[:Azure][:is_consolidated] = azure_consolidated_status(tenant, options)

    adapters_status[:Azure][:mpn_type] = false
    if azure_billing_adap.present?
      mpn_type = azure_billing_adap.azure_account_type.eql?('csp') || (azure_billing_adap.present? && azure_billing_adap.subscription && azure_billing_adap.subscription.quota_id && azure_billing_adap.subscription.quota_id.include?('MPN'))
      adapters_status[:Azure][:mpn_type] = mpn_type
    end

    adapters_status[:Azure][:data_in_progress] = adapter_file_info_response(azure_billing_adap.try(:id))
    adapters_status
  end

  def self.azure_consolidated_status(tenant, options)
    flag = false
    mapped_billing_adapter_ids = []
    normal_subscription_ids = tenant.adapters.azure_adapter.normal_adapters.pluck("data-> 'subscription_id'").uniq
    CurrentAccount.client_db = tenant.organisation.account
    AzureAccountIds.each do |azureAccountId|
      modified_subscription_ids = normal_subscription_ids - azureAccountId.subscription_ids
      mapped_billing_adapter_ids.push(azureAccountId.adapter_id) unless modified_subscription_ids.count.eql?(normal_subscription_ids.count)
    end
    azure_billing_adapter_ids = tenant.adapters.azure_adapter.billing_adapters.active_adapters.pluck(:id) - tenant.organisation.shared_adapters.azure_adapter.pluck(:id)
    azure_adapter_ids = (mapped_billing_adapter_ids + azure_billing_adapter_ids).uniq
    adapters = Adapters::Azure.active_adapters.where(id: azure_adapter_ids)
    adapters = adapters.collect do |billing_adapter|
      (%w[ea csp].include?(billing_adapter.azure_account_type) ||
        billing_adapter.azure_export_configurations.pluck(:status).include?(true)) ? billing_adapter : nil
    end.compact
    return flag unless adapters.size > 1

    currencies = []
    adapters.map do |adapter|
      unless adapter.azure_account_type.eql?('csp')
        currencies << adapter.currency
      else
        currencies << adapter.billing_currencies.pluck(:currency)
      end
    end
    currencies = currencies.flatten
    if options[:user].present? && options[:user].reset_to_default_currency == true
      currencies.uniq.count == 1
    elsif tenant.enable_currency_conversion
      return true if currencies.uniq.count == 1

      currency_configurations = CurrencyConfiguration.where(organisation_id: tenant.organisation_id, provider: 'Azure')
      return false if currency_configurations.blank?

      # user level checking
      if options[:user].present? && options[:user].override_tenant_currency
        user_currency = options[:user].try(:default_currency)
        return true if az_rolled_up_check_succeeded?(currencies, currency_configurations, user_currency)
      end

      # fallback to tenant level in case user level checks does not match
      tenant_currency = tenant.default_currency
      az_rolled_up_check_succeeded?(currencies, currency_configurations, tenant_currency)
    elsif !tenant.enable_currency_conversion
      currencies.uniq.count == 1
    end
  end

  def self.az_rolled_up_check_succeeded?(currencies, currency_configurations, preferred_currency)
    rolled_up_view_available = true
    currencies.each do |currency|
      next if currency == preferred_currency

      return false unless currency_configurations.detect do |config|
        config.cloud_provider_currency == currency && config.default_currency == preferred_currency
      end
    end
    rolled_up_view_available
  end

  def self.gcp_adapter_status(tenant, adapters_status)
    gcp_billing_adap = Adapter.find_by_id(tenant.current_gcp_billing_adapter_id)
    is_gcp_normal_adp_exist = tenant.adapters.gcp_normal_active_adapters.exists? rescue false

    adapters_status[:GCP][:is_billing_adapter_present] = true if gcp_billing_adap.try(:is_billing)
    adapters_status[:GCP][:is_normal_adapter_present] = is_gcp_normal_adp_exist
    adapters_status[:GCP][:is_report_config_present] = true if gcp_billing_adap.try(:is_billing)

    adapters_status[:GCP][:data_in_progress] = adapter_file_info_response(gcp_billing_adap.try(:id))
    adapters_status
  end

  def self.adapter_file_info_response(adapter_id)
    return false if adapter_id.blank?
    CurrentAccount.client_db = Adapter.find_by(id: adapter_id).account
    other_month_status = FileInfo.by_adapter(adapter_id).not.where(month: Date.today.strftime("%Y-%m")).pluck(:status).uniq
    current_month_status = FileInfo.by_adapter(adapter_id).where(month: Date.today.strftime("%Y-%m")).pluck(:status)
    !(other_month_status.include?('success') || current_month_status.include?('progress'))
  end

  def self.get_permitted_users(organisation, tenant, page_params, &block)
    org_users = organisation.tenants.where(id: tenant).first.users
    users = org_users.joins(:user_roles_users).active.uniq if org_users.present?
    users, total_records = apply_pagination(users, page_params)
    status Status, :success, [users, total_records], &block
    return users
  end

  def self.selected_users(organisation, current_tenant, user_params, users)
    users = users.where('username ILIKE ? OR name ILIKE ? ', "%#{user_params['query']}%", "%#{user_params['query']}%") if user_params['query'].present?
    users = users.where('email ILIKE ? OR unconfirmed_email ILIKE ?', "%#{user_params['email']}%", "%#{user_params['email']}%") if user_params['email'].present? && users.present?
    users = filter_users_state(organisation, user_params, users) if user_params['state'].present?
    users = filter_users_role(user_params, users, organisation) if user_params['roles'].present?
    users
  end

  def self.filter_users_state(organisation, user_params, users)
    user_states = user_params["state"].split(',')
    user_ids = OrganisationUser.where(organisation_id: organisation.id, user_id: users.pluck(:id), state: get_user_status(user_states) ).compact.pluck(:user_id)
    User.where(id: user_ids)
  end

  def self.get_user_status(state_params)
    state_params.map { |state| state.eql?("enabled") ? "active" : state }
  end

  def self.filter_users_role(user_params, users, organisation)
    roles = user_params["roles"].split(',')
    user_role_users = UserRole.includes(:user_roles_users)
    users.select do |user|
      user_roles = user_role_users.where(user_roles_users: { user_id: user.id, tenant_id: organisation.tenants.ids }).pluck(:name)
      (user_roles & roles).present?
    end
  end

  def self.filter_user_last_activity_and_tenants(users, organisation, current_tenant)
    user_activities = UserActivity.list_account_activities(organisation.account.id, current_tenant, organisation)
    user_roles = UserRole.joins(:user_roles_users).where(user_roles_users: {tenant_id: organisation.tenants.ids })
    users.inject([]) do |memo, user|
      user_activity = user_activities.by_username(user.username).order('created_at DESC')
      last_activity = user_activity.try(:first).try(:created_at)
      time_zone = user.time_zone.map { |_k, v| [v].flatten.join(',').to_s }.uniq.join('/')
      user.last_activity = last_activity.in_time_zone(TZInfo::Timezone.get(time_zone)) if last_activity.present?
      user.organisation_tenants = user.tenants.by_organisation(organisation.id)
      user.all_user_roles = user_roles.where(user_roles_users: { user_id: user.id }).pluck(:name).uniq
      memo << user
    end
  end

end
