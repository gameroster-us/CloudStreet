class CreateUserRolesUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :user_roles_users do |t|
      t.uuid :user_id, index: true
      t.uuid :user_role_id, index: true
    end
  end
end
