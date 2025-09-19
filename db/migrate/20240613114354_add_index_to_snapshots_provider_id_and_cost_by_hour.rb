class AddIndexToSnapshotsProviderIdAndCostByHour < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :snapshots, [:provider_id, :cost_by_hour], algorithm: :concurrently unless index_exists?(:snapshots, [:provider_id, :cost_by_hour])
  end

end
