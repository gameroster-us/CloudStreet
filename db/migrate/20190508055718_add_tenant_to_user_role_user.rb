class AddTenantToUserRoleUser < ActiveRecord::Migration[5.1]
  def change
    add_reference :user_roles_users, :tenant, type: :uuid, foreign_key: true
  end
end
