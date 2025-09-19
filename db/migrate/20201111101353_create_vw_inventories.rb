# frozen_string_literal: true

class CreateVwInventories < ActiveRecord::Migration[5.1]
  def change
    create_table :vw_inventories, id: :uuid do |t|
      t.json :data
      t.string :type
      t.uuid :vcenter_id
      t.uuid :vw_vdc_id
      t.uuid :parent_id
      t.timestamps
    end
    add_index :vw_inventories, :vcenter_id
    add_index :vw_inventories, :vw_vdc_id
    add_index :vw_inventories, :type
  end
end
