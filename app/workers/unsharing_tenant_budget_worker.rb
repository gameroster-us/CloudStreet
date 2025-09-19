# frozen_string_literal: true

class UnsharingTenantBudgetWorker

  include Sidekiq::Worker
  sidekiq_options queue: :budget_queue, backtrace: true

  def perform(tenant_id)
    BudgetProcess.info "=======UnsharingTenantBudgetWorker: #{tenant_id}======"
    tenant = Tenant.find_by(id: tenant_id)
    return if tenant.blank?

    unshare_gcp_budget(tenant)
    unshare_aws_budget(tenant)
    unshare_azure_budget(tenant)
    unshare_vm_ware_budget(tenant)
  end

  def unshare_gcp_budget(tenant)
    BudgetProcess.info "=======Gcp Budgets======"
    Budget.joins(:tenant_budgets).where(type: 'Budgets::GCP', tenant_budgets: { tenant_id: tenant.id, is_shared: true }).each do |budget|
      begin
        BudgetProcess.info "======Budget Details #{budget.name}, Tenant: #{budget.tenant_id}========="
        budget_projects = budget.budget_accounts.pluck(:provider_account_id)
        if budget.is_accounts_select_all
          tenant_budget_destroy(tenant, budget.id) unless tenant_gcp_billing_adapter(tenant, budget.adapter_id) || having_gcp_normal_adapters_of_tenant(tenant, budget.adapter_id)
        else
          tenant_budget_destroy(tenant, budget.id) unless tenant.gcp_project_ids.any? { |project| budget_projects.include?(project) } || tenant_gcp_billing_adapter(tenant, budget.adapter_id)
        end
      rescue StandardError => e
        Honeybadger.notify(error_class: 'UnsharingTenantBudgetWorker', error_message: "#{e.message}", parameters: { tenant_id: budget.tenant_id, organisation_id: budget.organisation_id }) if ENV['HONEYBADGER_API_KEY']
      end
    end
  end

  def tenant_gcp_billing_adapter(tenant, adapter_id)
    tenant.original_adapters.gcp_adapter.billing_adapters.where(id: adapter_id).exists?
  end

  def having_gcp_normal_adapters_of_tenant(tenant, adapter_id)
    projects = tenant.gcp_project_ids
    adapter = Adapter.find_by(id: adapter_id)
    CurrentAccount.client_db = adapter.account
    gcp_projects = GCPProjectIds.where(adapter_id: adapter.id).pluck(:project_ids).flatten.uniq
    linked_normal_projects = tenant.adapters.gcp_adapter.normal_adapters.include_not_configured.where("data->'project_id' IN(?)", gcp_projects).pluck("data").pluck("project_id").uniq
    projects.any? { |project| linked_normal_projects.include?(project) }
  end

  def unshare_aws_budget(tenant)
    Budget.joins(:tenant_budgets).where(type: 'Budgets::AWS', tenant_budgets: { tenant_id: tenant.id, is_shared: true }).each do |budget|
      begin
        BudgetProcess.info "======Budget Details #{budget.name}, Tenant: #{budget.tenant_id}========="
        budget_accounts = budget.budget_accounts.pluck(:provider_account_id) + fetch_service_groups_accounts(budget.budget_groups.pluck(:group_id) || [])
        if  budget.is_accounts_select_all
          tenant_budget_destroy(tenant, budget.id) unless tenant_aws_billing_adapter(tenant, budget.adapter_id) || having_aws_normal_adapters_of_tenant(tenant, budget.adapter_id)
        else
          tenant_budget_destroy(tenant, budget.id) unless tenant.aws_account_ids.any? { |account| budget_accounts.include?(account) } || tenant_aws_billing_adapter(tenant, budget.adapter_id)
        end
      rescue StandardError => e
        Honeybadger.notify(error_class: 'UnsharingTenantBudgetWorker', error_message: "#{e.message}", parameters: { tenant_id: budget.tenant_id, organisation_id: budget.organisation_id }) if ENV['HONEYBADGER_API_KEY']
      end
    end
  end

  def fetch_service_groups_accounts(service_group_ids)
    adapter_groups = ServiceGroup.adapterids_from_adapter_group(service_group_ids || [])
    Adapter.where(id: adapter_groups).map { |ada| ada.data['aws_account_id'] }.compact.uniq
  end

  def tenant_aws_billing_adapter(tenant, adapter_id)
    tenant.original_adapters.aws_adapter.billing_adapters.where(id: adapter_id).exists?
  end

  def having_aws_normal_adapters_of_tenant(tenant, adapter_id)
    accounts = tenant.aws_account_ids
    adapter = Adapter.find_by(id: adapter_id)
    CurrentAccount.client_db = adapter.account
    aws_accounts = AWSAccountIds.where(adapter_id: adapter.id).pluck(:aws_accounts).flatten.uniq
    aws_accounts = aws_accounts.map { |aws_acc| aws_acc.rjust(12, '0') }
    linked_normal_accounts =  tenant.adapters.aws_adapter.normal_adapters.include_not_configured.where("data->'aws_account_id' IN(?)", aws_accounts).pluck("data").pluck("aws_account_id").uniq
    accounts.any? { |account| linked_normal_accounts.include?(account) }
  end

  def unshare_azure_budget(tenant)
    Budget.joins(:tenant_budgets).where(type: 'Budgets::Azure', tenant_budgets: { tenant_id: tenant.id, is_shared: true }).each do |budget|
      begin
        BudgetProcess.info "======Budget Details #{budget.name}, Tenant: #{budget.tenant_id}========="
        bugdet_subscriptions = budget.budget_accounts.pluck(:provider_account_id) + subscriptions_from_adapter_groups(budget.budget_groups.pluck(:group_id) || [])
        if budget.is_accounts_select_all
          tenant_budget_destroy(tenant, budget.id) unless tenant_azure_billing(tenant, budget.adapter_id) || having_azure_normal_adapters_of_tenant(tenant, budget.adapter_id)
        else
          tenant_budget_destroy(tenant, budget.id) unless tenant.subscription_ids.any? { |subscription| bugdet_subscriptions.include?(subscription) } || tenant_azure_billing(tenant, budget.adapter_id)
        end
      rescue StandardError => e
        Honeybadger.notify(error_class: 'UnsharingTenantBudgetWorker', error_message: "#{e.message}", parameters: { tenant_id: budget.tenant_id, organisation_id: budget.organisation_id }) if ENV['HONEYBADGER_API_KEY']
      end
    end
  end

  def tenant_azure_billing(tenant, adapter_id)
    tenant.original_adapters.azure_adapter.billing_adapters.where(id: adapter_id).exists?
  end

  def subscriptions_from_adapter_groups(adapter_group_ids)
    ServiceGroup.adapterids_from_adapter_group(adapter_group_ids).map { |adapter_id| Adapter.find_by(id: adapter_id).try(:subscription_id) }.compact
  end

  def having_azure_normal_adapters_of_tenant(tenant, adapter_id)
    tenant_subscriptions = tenant.subscription_ids
    adapter = Adapter.find_by(id: adapter_id)
    CurrentAccount.client_db = adapter.account
    subscriptions = AzureAccountIds.where(adapter_id: adapter.id).first.try(:subscription_ids) || []
    linked_normal_subscriptions = tenant.adapters.azure_adapter.normal_adapters.include_not_configured.where("data->'subscription_id' IN(?)", subscriptions).pluck("data").pluck("subscription_id").uniq
    linked_normal_subscriptions.any? { |subscription| tenant_subscriptions.include?(subscription) }
  end

  def unshare_vm_ware_budget(tenant)
    Budget.joins(:tenant_budgets).where(type: 'Budgets::VmWare', tenant_budgets: { tenant_id: tenant.id, is_shared: true }).each do |budget|
      begin
        BudgetProcess.info "======Budget Details #{budget.name}, Tenant: #{budget.tenant_id}========="
        tenant_budget_destroy(tenant, budget.id) if tenant.adapters.where(type: 'Adapters::VmWare', id: budget.adapter_id).empty?
      rescue StandardError => e
        Honeybadger.notify(error_class: 'UnsharingTenantBudgetWorker', error_message: "#{e.message}", parameters: { tenant_id: budget.tenant_id, organisation_id: budget.organisation_id }) if ENV['HONEYBADGER_API_KEY']
      end
    end
  end

  def tenant_budget_destroy(tenant, budget_id)
    tenant.tenant_budgets.where(budget_id: budget_id).destroy_all
  end

end
