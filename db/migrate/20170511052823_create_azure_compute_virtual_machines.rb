class CreateAzureComputeVirtualMachines < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_virtual_machines, id: :uuid do |t|
      t.string :name, null: false
      t.string :location, null: false
      t.text :provider_id
      t.string :vm_size
      t.text :network_interfaces, array: true, default: []
      t.text :availability_set
      t.json :os_profile
      t.string :vm_id
      t.string :publisher, null: false
      t.string :offer, null: false
      t.string :sku, null: false
      t.string :version, null: false
      t.string :azure_resource_type, null: false

      t.uuid :account_id, index: true
      t.uuid :adapter_id, index: true    
      t.uuid :region_id, index: true   
      t.uuid :subscription_id, index: true    
      t.uuid :resource_group_id, index:true

      t.uuid :CS_service_id

      t.timestamps
    end
    add_index :azure_virtual_machines, :adapter_id
    add_index :azure_virtual_machines, :subscription_id
    add_index :azure_virtual_machines, :resource_group_id
  end
end
