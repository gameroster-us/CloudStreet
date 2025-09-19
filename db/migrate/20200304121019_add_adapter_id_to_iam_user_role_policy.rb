class AddAdapterIdToIamUserRolePolicy < ActiveRecord::Migration[5.1]
  def change
  	add_column :iam_user_role_policies, :adapter_id, :uuid 
  end
end
