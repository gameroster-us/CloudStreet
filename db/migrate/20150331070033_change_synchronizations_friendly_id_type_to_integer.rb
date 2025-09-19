class ChangeSynchronizationsFriendlyIdTypeToInteger < ActiveRecord::Migration[5.1]
  def self.up
    remove_column :synchronizations, :friendly_id, :string
    add_column :synchronizations, :friendly_id, :integer
  end

  def self.down
    remove_column :synchronizations, :friendly_id, :integer
    add_column :synchronizations, :friendly_id, :string
  end
end
