class AddIndexToSynchronizations < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :synchronizations, :adapter_ids, algorithm: :concurrently, name: 'idx_synchronizations_adapter_ids', using: 'gin'
    add_index :synchronizations, [:adapter_ids, :created_at], algorithm: :concurrently, name: 'idx_synchronizations_adapter_ids_created_at_desc'
  end
end
