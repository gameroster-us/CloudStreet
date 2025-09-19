class AddCompositeIndexToServiceAdviserConfigsAccountIdServiceType < ActiveRecord::Migration[5.2]
    disable_ddl_transaction!
  
    def change
      add_index :service_adviser_configs, [:account_id, :service_type], algorithm: :concurrently, name: 'index_service_advisor_account_id_service_type', using: :btree unless index_exists?(:service_adviser_configs, [:account_id, :service_type])
    end
end
  