class CreateAzureNetworkPublicIpAddresses < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_public_ip_addresses, id: :uuid do |t|
      t.string :name, null: false
      t.string :location, null: false
      t.string :azure_resource_type, null: false
      t.string :public_ipallocation_method
      t.integer :idle_timeout_in_minutes
      t.string :ip_address
      t.text :provider_id

      t.uuid :account_id, index: true
      t.uuid :adapter_id, index: true    
      t.uuid :region_id, index: true   
      t.uuid :subscription_id, index: true    
      t.uuid :resource_group_id, index:true

      t.uuid :CS_service_id

      t.timestamps
    end
    add_index :azure_public_ip_addresses, :adapter_id
    add_index :azure_public_ip_addresses, :subscription_id
    add_index :azure_public_ip_addresses, :resource_group_id
  end
end
