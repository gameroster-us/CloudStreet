class AddRoleIdsToVpcs < ActiveRecord::Migration[5.1]
  def change
    add_column :vpcs, :user_role_ids, :uuid, array: true, default: [], :null => false
  end
end
