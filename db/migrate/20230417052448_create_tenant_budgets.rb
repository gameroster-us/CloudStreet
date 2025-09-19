class CreateTenantBudgets < ActiveRecord::Migration[5.1]
  def change
    create_table :tenant_budgets, id: :uuid do |t|
      t.float  :prev_month_cost
      t.float  :forecast_cost
      t.boolean :over_budget
      t.boolean :threshold_budget
      t.json   :monthly_email_flag, array: true, default: []
      t.jsonb   :monthly_threshold_email_flag, array: true, default: [{}]
      t.jsonb   :monthly_cost_to_date, array: true, default: [{}]
      t.references :tenant, type: :uuid, foreign_key: true
      t.references :budget, type: :uuid, foreign_key: true
      t.string  :state
      t.timestamps
    end
  end
end
