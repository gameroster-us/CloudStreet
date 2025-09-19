class ChangeSyncToInSynchronization < ActiveRecord::Migration[5.1]
  def change
  	remove_column :synchronizations, :sync_up
  	add_column :synchronizations, :synced_to,:string 
  end
end
