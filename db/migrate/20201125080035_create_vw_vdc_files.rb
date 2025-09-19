# frozen_string_literal: true

class CreateVwVdcFiles < ActiveRecord::Migration[5.1]
  def change
    create_table :vw_vdc_files, id: :uuid do |t|
      t.uuid :vw_vdc_id
      t.string :zip
      t.timestamps
    end
    add_index :vw_vdc_files, :vw_vdc_id
    add_foreign_key :vw_vdc_files, :vw_vdcs, on_delete: :cascade
  end
end
