# frozen_string_literal: true

class DropTableVwVdc < ActiveRecord::Migration[5.1]
  def change
    remove_foreign_key :vw_vcenters, column: :vw_vdc_id
    remove_foreign_key :vw_vdc_files, column: :vw_vdc_id
    rename_column :vw_vdc_files, :vw_vdc_id, :adapter_id
    rename_column :vw_vcenters, :vw_vdc_id, :adapter_id

    drop_table :vw_vdcs, id: :uuid do |t|
      t.string :name
      t.uuid :account_id
      t.timestamps
    end
  end
end
