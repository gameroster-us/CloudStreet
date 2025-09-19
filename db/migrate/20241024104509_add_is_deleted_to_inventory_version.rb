class AddIsDeletedToInventoryVersion < ActiveRecord::Migration[5.2]
  def change
    add_column :vw_inventory_versions, :is_deleted, :boolean, default: false
  end
end
