class AddBunkerOptionInBackupPolicy < ActiveRecord::Migration[5.1]
  def change
    add_column :backup_policies, :is_bunker_option, :boolean
    add_column :backup_policies, :is_source_copy, :boolean
  end
end
