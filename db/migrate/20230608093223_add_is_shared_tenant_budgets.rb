class AddIsSharedTenantBudgets < ActiveRecord::Migration[5.2]
  def change
    add_column :tenant_budgets, :is_shared, :boolean, default: false
  end
end
