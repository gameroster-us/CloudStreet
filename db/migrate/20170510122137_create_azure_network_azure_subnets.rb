class CreateAzureNetworkAzureSubnets < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_subnets, id: :uuid do |t|
      t.string :name, null: false
      t.string :location, null: false
      t.string :address_prefix, null: false
      t.text :provider_id
      t.string :azure_resource_type, null: false
      
      t.uuid :account_id, index: true
      t.uuid :adapter_id, index: true    
      t.uuid :region_id, index: true   
      t.uuid :subscription_id, index: true    
      t.uuid :resource_group_id, index:true

      t.uuid :CS_service_id

      t.timestamps
    end
    add_index :azure_subnets, :adapter_id
    add_index :azure_subnets, :subscription_id
    add_index :azure_subnets, :resource_group_id
  end
end
