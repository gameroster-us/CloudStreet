class CreateAzureNetworkNetworkInterfaces < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_network_interfaces, id: :uuid do |t|
      t.string :name, null: false
      t.string :location, null: false
      t.string :azure_resource_type, null: false
      t.json :ip_configurations
      t.boolean :enable_ip_forwarding
      t.json :dns_settings
      t.text :provider_id

      t.uuid :account_id, index: true
      t.uuid :adapter_id, index: true    
      t.uuid :region_id, index: true   
      t.uuid :subscription_id, index: true    
      t.uuid :resource_group_id, index:true

      t.uuid :CS_service_id

      t.timestamps
    end
    add_index :azure_network_interfaces, :adapter_id
    add_index :azure_network_interfaces, :subscription_id
    add_index :azure_network_interfaces, :resource_group_id
  end
end
