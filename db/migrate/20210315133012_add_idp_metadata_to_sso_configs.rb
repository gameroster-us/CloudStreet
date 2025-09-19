class AddIdpMetadataToSsoConfigs < ActiveRecord::Migration[5.1]
  def change
    add_column :sso_configs, :idp_metadata, :text
  end
end
