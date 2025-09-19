class AddIsServiceSelectAllToBudgets < ActiveRecord::Migration[5.2]
  def change
    add_column :budgets, :is_service_select_all, :boolean, default: false
  end
end
