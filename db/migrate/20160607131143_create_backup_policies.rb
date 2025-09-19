class CreateBackupPolicies < ActiveRecord::Migration[5.1]
  def change
    create_table :backup_policies, id: :uuid do |t|
      t.string :name
      t.uuid :environment_ids, array: true, default: []
      t.json :backupable_services
      t.uuid :region_id
      t.uuid :adapter_id
      t.uuid :account_id, index: true
      t.uuid :created_by_user_id, index: true
      t.uuid :updated_by_user_id, index: true

      t.timestamps
    end
    execute "ALTER TABLE backup_policies ALTER COLUMN backupable_services SET DEFAULT '{}'"
  end
end
