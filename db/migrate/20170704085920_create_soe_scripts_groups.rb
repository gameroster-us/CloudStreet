class CreateSoeScriptsGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :soe_scripts_groups, id: :uuid do |t|
      t.string :name, index: true, not_null: true
      t.string :supported_os, not_null: true
      t.integer :soe_config_count, not_null: true, default: 0
      t.integer :sourceable_id, not_null: true
      t.string  :sourceable_type, not_null: true
      #TODO delete cascade
      t.timestamps
    end
    add_index :soe_scripts_groups, [:sourceable_type, :sourceable_id]
    add_foreign_key(:soe_scripts, :soe_scripts_groups, on_delete: :cascade, column: :soe_scripts_group_id)

  end
end
