class AddDataColumnToBudgets < ActiveRecord::Migration[5.2]
  def change
    add_column :budgets, :data, :jsonb, default: {}
  end
end
