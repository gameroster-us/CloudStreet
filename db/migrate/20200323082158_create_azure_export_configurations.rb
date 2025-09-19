class CreateAzureExportConfigurations < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_export_configurations, id: :uuid do |t|
      t.string :name
      t.string :container
      t.string :directory
      t.string :subscription_id
      t.string :storage_account_id
      t.string :resource_group_name
      t.boolean :status, default: true
      t.uuid   :adapter_id
      
      t.timestamps
    end
    add_foreign_key :azure_export_configurations, :adapters, on_delete: :cascade
    add_index :azure_export_configurations, :adapter_id
  end
end
