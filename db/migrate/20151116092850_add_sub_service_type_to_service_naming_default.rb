class AddSubServiceTypeToServiceNamingDefault < ActiveRecord::Migration[5.1]
  def change
    add_column :service_naming_defaults, :sub_service_type, :string
  end
end
