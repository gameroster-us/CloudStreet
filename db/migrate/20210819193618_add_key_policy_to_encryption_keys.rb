class AddKeyPolicyToEncryptionKeys < ActiveRecord::Migration[5.1]
  def change
  	add_column :encryption_keys, :key_policy, :json
  end
end
