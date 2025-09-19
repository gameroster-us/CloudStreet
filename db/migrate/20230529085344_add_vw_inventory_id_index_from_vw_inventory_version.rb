class AddVwInventoryIdIndexFromVwInventoryVersion < ActiveRecord::Migration[5.1]
  def change
    add_index :vw_inventory_versions, :vw_inventory_id
  end
end
