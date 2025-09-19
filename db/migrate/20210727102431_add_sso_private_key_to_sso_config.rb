class AddSsoPrivateKeyToSsoConfig < ActiveRecord::Migration[5.1]
  def change
    add_column :sso_configs, :private_key, :text
  end
end
