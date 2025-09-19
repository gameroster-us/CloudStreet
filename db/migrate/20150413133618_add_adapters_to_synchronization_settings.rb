class AddAdaptersToSynchronizationSettings < ActiveRecord::Migration[5.1]
  def self.up
    add_column :synchronization_settings, :adapters, :uuid, array: true, default: []
    remove_column :synchronization_settings, :adapter_id
  end

  def self.down
    add_column :synchronization_settings, :adapter_id, :uuid
    remove_column :synchronization_settings, :adapters
  end
end
