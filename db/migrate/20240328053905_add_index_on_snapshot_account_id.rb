class AddIndexOnSnapshotAccountId < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  def change
    add_index :snapshots, :account_id, algorithm: :concurrently unless index_exists?(:snapshots, :account_id)
  end
end
