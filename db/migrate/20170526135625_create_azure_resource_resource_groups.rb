class CreateAzureResourceResourceGroups < ActiveRecord::Migration[5.1]
  def change
    drop_table :azure_resource_groups  if (table_exists? :azure_resource_groups)
    create_table :azure_resource_groups, id: :uuid do |t|
      t.string :name, null: false
      t.string :location, null: false
      t.text :provider_id
      t.string :azure_resource_type
      t.json :properties

      t.uuid :account_id, index: true
      t.uuid :adapter_id, index: true    
      t.uuid :region_id, index: true   
      t.uuid :subscription_id, index: true    

      t.uuid :CS_service_id

      t.timestamps
    end
    add_index :azure_resource_groups, :adapter_id
    add_index :azure_resource_groups, :subscription_id
  end
end
