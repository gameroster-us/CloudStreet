class AzureResourceConnections < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_resource_connections, id: false do |t|
      t.uuid :resource_id, index: true, foreign_key: { to_table: 'azure_resources' }
      t.uuid :associated_resource_id, index: true, foreign_key: { to_table: 'azure_resources' }
      t.index [:resource_id, :associated_resource_id], name: "azure_resource_association_with child"
      t.index [:associated_resource_id, :resource_id], name: "azure_resource_association_with parent"
    end
    add_foreign_key :azure_resource_connections, :azure_resources, column: :resource_id, on_delete: :cascade
    add_foreign_key :azure_resource_connections, :azure_resources, column: :associated_resource_id, on_delete: :cascade
  end
end
