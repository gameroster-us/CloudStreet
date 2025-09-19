class AddColumnToUserRole < ActiveRecord::Migration[5.1]
  def change
    add_column :user_roles, :organisation_id, :uuid
    add_foreign_key :user_roles, :organisations, on_delete: :cascade
    add_index :user_roles, :organisation_id
    Account.all.each do |account|
      UserRole.where(account_id: account.id).update_all(organisation_id: account.organisation_id)
    end
    remove_column :user_roles, :account_id, :uuid
  end
end
