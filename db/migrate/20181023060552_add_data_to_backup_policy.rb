class AddDataToBackupPolicy < ActiveRecord::Migration[5.1]
  def change
    add_column :backup_policies, :data, :json, default: {}
  end
end