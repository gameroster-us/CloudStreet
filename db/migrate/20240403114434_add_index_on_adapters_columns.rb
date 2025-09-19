class AddIndexOnAdaptersColumns < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  def change
    add_index :adapters, :adapter_purpose, algorithm: :concurrently unless index_exists?(:adapters, :adapter_purpose)
    add_index :adapters, :state, algorithm: :concurrently unless index_exists?(:adapters, :state)
    add_index :adapters, :account_id, algorithm: :concurrently unless index_exists?(:adapters, :account_id)
  end
end
