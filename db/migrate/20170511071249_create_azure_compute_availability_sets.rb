class CreateAzureComputeAvailabilitySets < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_availability_sets, id: :uuid do |t|
      t.string :name, null: false
      t.string :location, null: false
      t.text :provider_id
      t.integer :update_domain_count, default: 1, null: false
      t.integer :fault_domain_count, default: 1, null: false
      t.boolean :managed, default: false
      t.string :azure_resource_type, null: false

      t.uuid :account_id, index: true
      t.uuid :adapter_id, index: true    
      t.uuid :region_id, index: true   
      t.uuid :subscription_id, index: true    
      t.uuid :resource_group_id, index:true

      t.uuid :CS_service_id

      t.timestamps
    end
    add_index :azure_availability_sets, :adapter_id
    add_index :azure_availability_sets, :subscription_id
    add_index :azure_availability_sets, :resource_group_id
  end
end
