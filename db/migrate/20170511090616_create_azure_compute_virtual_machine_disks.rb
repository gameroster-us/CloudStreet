class CreateAzureComputeVirtualMachineDisks < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_disks, id: :uuid do |t|
      t.string :name, null: false
      t.string :location, null: false
      t.text :provider_id
      t.string :create_option, null: false
      t.json :image_reference
      t.text :vhd_uri, null: false
      t.string :caching, null: false
      t.string :disk_type, null: false
      t.string :azure_resource_type, null: false

      t.uuid :account_id, index: true
      t.uuid :adapter_id, index: true    
      t.uuid :region_id, index: true   
      t.uuid :subscription_id, index: true    
      t.uuid :resource_group_id, index:true

      t.uuid :CS_service_id

      t.timestamps
    end
    add_index :azure_disks, :adapter_id
    add_index :azure_disks, :subscription_id
    add_index :azure_disks, :resource_group_id
  end
end
