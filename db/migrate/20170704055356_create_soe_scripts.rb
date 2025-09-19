class CreateSoeScripts < ActiveRecord::Migration[5.1]
  def change
    create_table :soe_scripts, id: :uuid do |t|
      t.string :name, not_null: true
      t.datetime :last_updated, not_null: true
      t.string :type, not_null: true
      t.text :script_text, not_null: true
      t.uuid :soe_scripts_group_id, not_null: true

      t.timestamps
    end
  end
end
