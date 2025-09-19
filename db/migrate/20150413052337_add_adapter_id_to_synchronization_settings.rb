class AddAdapterIdToSynchronizationSettings < ActiveRecord::Migration[5.1]
 def self.up
    add_column :synchronization_settings, :adapter_id, :uuid
  end

  def self.down
    remove_column :synchronization_settings, :adapter_id, :uuid
  end
end
