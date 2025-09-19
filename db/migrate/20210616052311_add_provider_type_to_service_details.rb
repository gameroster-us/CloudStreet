class AddProviderTypeToServiceDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :service_details, :provider_type, :string, default: 'AWS'
  end
end
