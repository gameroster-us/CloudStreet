class AddBackupPolicyIdsInTask < ActiveRecord::Migration[5.1]
  def change
  	add_column :tasks, :backup_policy_id, :string
  end
end
