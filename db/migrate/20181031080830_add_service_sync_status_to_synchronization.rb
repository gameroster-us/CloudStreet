class AddServiceSyncStatusToSynchronization < ActiveRecord::Migration[5.1]
  def change
    add_column :synchronizations, :service_sync_status, :json
  end
end
