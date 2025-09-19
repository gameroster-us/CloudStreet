class AddFieldsToSsoConfigs < ActiveRecord::Migration[5.1]
  def change
    add_column :sso_configs, :name_attribute_key, :text, default: "Name"
    add_column :sso_configs, :roles_attribute_key, :text, default: "Role"
    add_column :sso_configs, :sso_keyword_attribute_key, :text, default: "Tenant"
  end
end
