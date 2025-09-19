class AddIndexIntoVwMetrics < ActiveRecord::Migration[5.1]
  def change
    add_index :vw_metrics, [:vw_inventory_id, :noted_at], unique: true
  end
end
