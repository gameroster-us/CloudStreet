class AddStatusToSynchronizationSettings < ActiveRecord::Migration[5.1]
  def change
    add_column :synchronization_settings, :status, :json
  end
end
