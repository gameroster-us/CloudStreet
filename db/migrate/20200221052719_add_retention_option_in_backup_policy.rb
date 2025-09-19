class AddRetentionOptionInBackupPolicy < ActiveRecord::Migration[5.1]
  def change
  	add_column :backup_policies, :is_backup_retention, :boolean
    add_column :backup_policies, :retention_period, :string
  end
end
