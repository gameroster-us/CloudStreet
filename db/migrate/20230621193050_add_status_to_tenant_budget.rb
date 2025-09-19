class AddStatusToTenantBudget < ActiveRecord::Migration[5.2]
  def change
    add_column :tenant_budgets, :status, :string, default: 'success'
  end
end
