class CreateTagKeys < ActiveRecord::Migration[5.1]
  def change
    create_table :tag_keys, id: :uuid do |t|
      t.string :key, :limit => 600, :null => false
      t.text :description

      t.timestamps

      t.uuid :account_id
      t.uuid :adapter_id
      t.uuid :region_id
      t.uuid :subscription_id
    end
    add_index :tag_keys, :adapter_id
    add_index :tag_keys, :subscription_id
    add_index :tag_keys, [:key, :adapter_id, :subscription_id, :region_id], :unique => true, :name => 'index_keys_on_tag_key_adapter_id_subscription_id_region_id'
  end
end
