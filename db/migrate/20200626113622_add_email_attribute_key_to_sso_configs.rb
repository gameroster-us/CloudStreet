class AddEmailAttributeKeyToSsoConfigs < ActiveRecord::Migration[5.1]
  def change
    add_column :sso_configs, :email_attribute_key, :text, default: "E-Mail Address"
  end
end
