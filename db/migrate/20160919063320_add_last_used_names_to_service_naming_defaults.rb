class AddLastUsedNamesToServiceNamingDefaults < ActiveRecord::Migration[5.1]
  def change
    add_column :service_naming_defaults, :last_used_names, :json, default: {}
  end
end
