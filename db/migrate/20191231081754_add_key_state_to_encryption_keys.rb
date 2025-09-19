class AddKeyStateToEncryptionKeys < ActiveRecord::Migration[5.1]
  def change
    add_column :encryption_keys, :key_state, :string
    add_column :encryption_keys, :key_enabled, :boolean
    add_column :encryption_keys, :key_rotation_enabled, :boolean
    add_column :encryption_keys, :key_policy_exposed, :boolean
  end
end
