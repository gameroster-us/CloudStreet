class AddIndexToServiceGroup < ActiveRecord::Migration[5.1]
  def change
    add_index :service_groups, :name
    add_index :service_groups, :tenant_id
    add_index :service_groups, :provider_type
    add_index :service_groups, :account_id
    add_index :service_groups, :billing_adapter_id
    add_index :service_groups, :customer_id
    add_index :service_groups, [:billing_adapter_id, :tenant_id, :account_id, :customer_id], name: 'customer_group'
  end
end
