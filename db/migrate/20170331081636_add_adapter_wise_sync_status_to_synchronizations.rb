class AddAdapterWiseSyncStatusToSynchronizations < ActiveRecord::Migration[5.1]
  def change
    add_column :synchronizations, :adapter_wise_sync_status, :hstore, :default => {}
  end
end
