class CreateTenantsResourceGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :tenants_resource_groups, id: :uuid do |t|
      t.uuid :tenant_id, index: true
      t.uuid :adapter_id, index: true
      t.uuid :azure_resource_group_id, index: true
    end

    add_foreign_key :tenants_resource_groups, :tenants
    add_foreign_key :tenants_resource_groups, :adapters
    add_foreign_key :tenants_resource_groups, :azure_resource_groups
    add_index :tenants_resource_groups, [:tenant_id, :adapter_id, :azure_resource_group_id], name: :tenant_adapter_rg_index
    add_index :tenants_resource_groups, [:adapter_id, :tenant_id, :azure_resource_group_id], name: :adapter_tenant_rg_index
  end
end
