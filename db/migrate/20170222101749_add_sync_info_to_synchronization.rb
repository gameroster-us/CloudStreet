class AddSyncInfoToSynchronization < ActiveRecord::Migration[5.1]
  def change
    add_column :synchronizations, :sync_info, :json
  end
end
