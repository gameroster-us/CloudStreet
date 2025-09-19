class RenameColumnRoleIdsToUserRoleIds < ActiveRecord::Migration[5.1]		
  def change		
    rename_column :organisation_images, :role_ids, :user_role_ids		
  end		
end
