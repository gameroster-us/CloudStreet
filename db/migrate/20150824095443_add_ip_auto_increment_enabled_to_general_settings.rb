class AddIpAutoIncrementEnabledToGeneralSettings < ActiveRecord::Migration[5.1]
  def change
    add_column :general_settings, :ip_auto_increment_enabled, :boolean, default: true
  end
end
