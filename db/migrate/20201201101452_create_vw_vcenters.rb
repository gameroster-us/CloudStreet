# frozen_string_literal: true

class CreateVwVcenters < ActiveRecord::Migration[5.1]
  def change
    create_table :vw_vcenters, id: :uuid do |t|
      t.uuid :vw_vdc_id
      t.json :data
      t.timestamps
    end

    add_index :vw_vcenters, :vw_vdc_id
    add_foreign_key :vw_vcenters, :vw_vdcs, on_delete: :cascade

    remove_column :vw_inventories, :vcenter_id, :uuid
    remove_column :vw_inventories, :vw_vdc_id, :uuid
    remove_column :vw_inventories, :type, :string

    add_column :vw_inventories, :vw_vcenter_id, :uuid
    add_column :vw_inventories, :resource_type, :string
    add_column :vw_metrics, :noted_at, :datetime

    add_column :vw_inventories, :name, :string
    add_column :vw_inventories, :tag, :string
    add_index :vw_inventories, :name
    add_index :vw_inventories, :vw_vcenter_id
    add_foreign_key :vw_inventories, :vw_vcenters, on_delete: :cascade
  end
end
