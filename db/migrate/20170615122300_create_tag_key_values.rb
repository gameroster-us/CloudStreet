class CreateTagKeyValues < ActiveRecord::Migration[5.1]
  def change
    create_table :tag_key_values, id: :uuid do |t|
      t.string :tag_value, :limit => 600, :null => false

      t.uuid :tag_key_id

      t.timestamps
    end
    add_index :tag_key_values, :tag_key_id
    add_index :tag_key_values, [:tag_key_id, :tag_value], :unique => true
  end
end
