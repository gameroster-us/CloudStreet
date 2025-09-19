class AddRegionsToSynchronizations < ActiveRecord::Migration[5.1]
  def self.up
    add_column :synchronizations, :region_ids, :uuid, array: true, default: []
  end

  def self.down
    remove_column :synchronizations, :region_ids
  end
end
