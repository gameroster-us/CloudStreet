# frozen_string_literal: true

# this class is used for process the budgets shared with tenant

class TenantBudgetCostCalculatorWorker

  include Sidekiq::Worker
  sidekiq_options queue: :budget_queue, retry: true, backtrace: true

  def perform(tenant_budget_id)
    tenant_budget = TenantBudget.find_by(id: tenant_budget_id)
    return if tenant_budget.blank? || !tenant_budget.try(:status).eql?('pending')

    tenant_budget.update(status: 'in_queue')

    CSLogger.info 'The Budget Process Started for Shared Budgets to Tenant of VmWare'
    begin
      Budget::BudgetDailyProcess::VmWare.calculate_tenant_budget_cost(tenant_budget)
    rescue StandardError => e
      tenant_budget.mark_error!
      CSLogger.error "Error : #{e.message}"
      CSLogger.error "BackTrace : #{e.backtrace.first}"
      Honeybadger.notify(e, error_class: 'TenantBudgetCostCalculatorWorker', error_message: "#{e.message}", parameters: { adapter_id: tenant_budget.budget.adapter_id, budget: tenant_budget.budget_id, tenant: tenant_budget.tenant_id }) if ENV['HONEYBADGER_API_KEY']
    end
  end

end
