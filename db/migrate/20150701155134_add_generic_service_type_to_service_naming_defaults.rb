class AddGenericServiceTypeToServiceNamingDefaults < ActiveRecord::Migration[5.1]
  def change
    add_column :service_naming_defaults, :generic_service_type, :string
  end
end
