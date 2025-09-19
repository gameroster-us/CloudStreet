class AddForeignKeyToAzureResource < ActiveRecord::Migration[5.1]
  def change
  	add_index :azure_resources, [:adapter_id, :azure_resource_group_id], name: "index_az_resource_on_adapter_id_and_resource_group_id"
  	add_index :azure_resources, [:adapter_id, :azure_resource_group_id, :region_id], name: "index_az_resource_on_adapter_and_resource_group_and_region"
	remove_foreign_key(:azure_resources, :adapters)
	add_foreign_key(:azure_resources, :adapters, column: 'adapter_id', on_delete: :cascade)
	remove_foreign_key(:azure_resources, :azure_resource_groups)
	add_foreign_key(:azure_resources, :azure_resource_groups, column: 'azure_resource_group_id', on_delete: :cascade)
	remove_foreign_key(:azure_resources, :regions)
	add_foreign_key(:azure_resources, :regions, column: 'region_id', on_delete: :cascade)
  end
end
