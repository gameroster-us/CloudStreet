class CreateServiceEncryptionKeys < ActiveRecord::Migration[5.1]
  def change
  	create_table :service_encryption_keys, id: :uuid  do |t|
      t.uuid :service_id
      t.uuid :encryption_key_id
    end
  end
end
