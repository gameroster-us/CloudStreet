class ChangeUserRoleIdsNotToNull < ActiveRecord::Migration[5.1]
  def change
    change_column_null :organisation_images, :user_role_ids, :uuid, array: true, default: [], :null => false
  end
end
