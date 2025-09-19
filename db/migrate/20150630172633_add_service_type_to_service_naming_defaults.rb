class AddServiceTypeToServiceNamingDefaults < ActiveRecord::Migration[5.1]
  def change
    add_column :service_naming_defaults, :service_type, :string
  end
end
