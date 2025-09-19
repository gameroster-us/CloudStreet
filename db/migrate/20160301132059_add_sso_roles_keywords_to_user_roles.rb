class AddSsoRolesKeywordsToUserRoles < ActiveRecord::Migration[5.1]
  def change
    add_column :user_roles, :sso_keywords, :text, array:true, default: []
  end
end
