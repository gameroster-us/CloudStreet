class CreateAzureStorageStorageAccounts < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_storage_accounts, id: :uuid do |t|
      t.string :name, null: false
      t.string :location, null: false
      t.text :provider_id
      t.string :azure_resource_type, null: false
      t.string :kind
      t.string :sku_name, null: false
      t.string :sku_tier, null: false

      t.uuid :account_id, index: true
      t.uuid :adapter_id, index: true    
      t.uuid :region_id, index: true   
      t.uuid :subscription_id, index: true    
      t.uuid :resource_group_id, index:true

      t.uuid :CS_service_id

      t.timestamps
    end
    add_index :azure_storage_accounts, :adapter_id
    add_index :azure_storage_accounts, :subscription_id
    add_index :azure_storage_accounts, :resource_group_id
  end
end
