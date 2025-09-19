class CreateBudgets < ActiveRecord::Migration[5.1]
  def change
    create_table :budgets, id: :uuid do |t|
      t.string :name
      t.string :description
      t.float  :max_amount
      t.uuid   :organisation_id
      t.uuid   :adapter_id
      t.json   :service_type, array: true, default: []
      t.jsonb   :budgets_tags, array: true, default: []
      t.json   :threshold_value, array: true, default: []
      t.jsonb  :monthly_wise_budget, array: true, default: []
      t.date   :start_month
      t.string :set_period
      t.boolean :is_accounts_select_all
      t.string :type
      t.date   :expires_date
      t.boolean :notify
      t.string   :notify_to, array: true, default: []
      t.string   :custom_emails, array: true, default: []

      t.references :tenant, type: :uuid, foreign_key: true
      t.timestamps
    end
  end
end
