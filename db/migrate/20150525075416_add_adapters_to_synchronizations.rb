class AddAdaptersToSynchronizations < ActiveRecord::Migration[5.1]
  def self.up
    add_column :synchronizations, :adapter_ids, :uuid, array: true, default: []
  end

  def self.down
    remove_column :synchronizations, :adapter_ids
  end
end
