class CreateEncryptionKeys < ActiveRecord::Migration[5.1]
  def change
    create_table :encryption_keys, id: :uuid do |t|
      t.string :key_alias
      t.string :description
      t.string :key_id
      t.string :arn
      t.boolean :enabled
      t.string :key_usage
      t.string :aws_account_id      
      t.datetime :creation_date
      t.uuid :account_id
      t.uuid :adapter_id
      t.uuid :region_id
      t.string :state

      t.timestamps
    end
  end
end
