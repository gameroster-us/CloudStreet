class AddAthenaGroupSyncRunninngToOrganisation < ActiveRecord::Migration[5.1]
  def change
    add_column :organisations, :athena_group_sync_running, :jsonb, default: { AWS: false, Azure: false, GCP: false }
  end
end
