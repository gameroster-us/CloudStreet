class MoveControlFromOrganisationToAccount < ActiveRecord::Migration[5.1]
  def change
  	remove_column :user_roles, :organisation_id
  	remove_column :users, :organisation_id
  	add_column :user_roles, :account_id, :uuid
  	add_column :accounts, :organisation_id, :uuid
  end
end
