class AddIndexOnServiceProviderAndAccountId < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  def change
    add_index :services, [:provider_id, :account_id], algorithm: :concurrently unless index_exists?(:services, [:provider_id, :account_id])
  end
end
