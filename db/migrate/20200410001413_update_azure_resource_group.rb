class UpdateAzureResourceGroup < ActiveRecord::Migration[5.1]
  def change
  	add_foreign_key :azure_resource_groups, :adapters
  	remove_foreign_key :azure_resource_groups, :CS_services
  	remove_column :azure_resource_groups, :CS_service_id
  	remove_column :azure_resource_groups, :azure_resource_type
  end
end
