class CreateCostAllocationRules < ActiveRecord::Migration[5.2]
  def change
    create_table :cost_allocation_rules, id: :uuid do |t|
      t.references :tenant, type: :uuid, foreign_key: true
      t.references :account, type: :uuid, foreign_key: true
      t.string :adapter_name
      t.string :name
      t.date :start_date
      t.date :expiry_date
      t.string :provider
      t.string :criteria
      t.string :mode
      t.json :source
      t.json :target
      t.jsonb :allocations, array: true, default: [{}]
      t.string :comment

      t.timestamps
    end
  end
end
