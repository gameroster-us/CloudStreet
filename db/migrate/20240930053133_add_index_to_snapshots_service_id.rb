class AddIndexToSnapshotsServiceId < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    unless index_exists?(:snapshots, :service_id, name: 'index_snapshots_on_service_id')
      add_index :snapshots, :service_id, name: 'index_snapshots_on_service_id', algorithm: :concurrently
    end
  end
end
