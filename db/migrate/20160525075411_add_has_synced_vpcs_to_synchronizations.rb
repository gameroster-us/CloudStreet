class AddHasSyncedVpcsToSynchronizations < ActiveRecord::Migration[5.1]
  def change
    add_column :synchronizations, :has_synced_vpcs, :boolean, :default => false
  end
end
