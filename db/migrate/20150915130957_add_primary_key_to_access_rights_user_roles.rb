class AddPrimaryKeyToAccessRightsUserRoles < ActiveRecord::Migration[5.1]
   def up
    drop_table :access_rights_user_roles
    create_table :access_rights_user_roles, :id => :uuid do |t|
        t.uuid :access_right_id
        t.uuid :user_role_id
    end
    add_index :access_rights_user_roles, [:access_right_id, :user_role_id],:name=>"index_access_rights_user_roles_on_right_id_and_role_id"
    add_index :access_rights_user_roles, :user_role_id
  end

  def down
    drop_table :access_rights_user_roles
    create_table :access_rights_user_roles, :id => false do |t|
        t.uuid :access_right_id
        t.uuid :user_role_id
    end
    add_index :access_rights_user_roles, [:access_right_id, :user_role_id],:name=>"index_access_rights_user_roles_on_right_id_and_role_id"
    add_index :access_rights_user_roles, :user_role_id
  end
end
