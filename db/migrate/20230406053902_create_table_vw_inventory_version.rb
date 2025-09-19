class CreateTableVwInventoryVersion < ActiveRecord::Migration[5.1]
  def change
    create_table :vw_inventory_versions, id: :uuid do |t|
      t.json :data
      t.uuid :vw_inventory_id
      t.timestamps
    end
  end
end
