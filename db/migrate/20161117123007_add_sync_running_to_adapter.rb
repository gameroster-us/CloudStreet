class AddSyncRunningToAdapter < ActiveRecord::Migration[5.1]
  def change
    add_column :adapters, :sync_running, :boolean, default: false
  end
end
