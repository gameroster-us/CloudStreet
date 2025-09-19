class CreateAzureNetworkLoadBalancers < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_load_balancers, id: :uuid do |t|
      t.string :name, null: false
      t.string :location, null: false
      t.text :provider_id
      t.json :frontend_ip_configurations
      t.json :backend_address_pools
      t.json :load_balancing_rules
      t.json :probes
      t.json :inbound_nat_rules
      t.json :outbound_nat_rules
      t.json :inbound_nat_pools
      t.string :azure_resource_type, null: false

      t.uuid :account_id, index: true
      t.uuid :adapter_id, index: true    
      t.uuid :region_id, index: true   
      t.uuid :subscription_id, index: true    
      t.uuid :resource_group_id, index:true

      t.uuid :CS_service_id
      t.timestamps
    end
    add_index :azure_load_balancers, :adapter_id
    add_index :azure_load_balancers, :subscription_id
    add_index :azure_load_balancers, :resource_group_id
  end
end
