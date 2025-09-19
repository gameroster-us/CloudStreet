# frozen_string_literal: true

class CreateVwMetrics < ActiveRecord::Migration[5.1]
  def change
    create_table :vw_metrics, id: :uuid do |t|
      t.json :data
      t.uuid :vw_inventory_id
      t.timestamps
    end
    add_index :vw_metrics, :vw_inventory_id
    add_foreign_key :vw_metrics, :vw_inventories, on_delete: :cascade
  end
end
