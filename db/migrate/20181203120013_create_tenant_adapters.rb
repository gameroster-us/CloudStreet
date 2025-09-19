class CreateTenantAdapters < ActiveRecord::Migration[5.1]
  def change
    create_table :tenant_adapters, id: :uuid do |t|
      t.uuid :tenant_id
      t.uuid :adapter_id

      t.timestamps
    end
    add_foreign_key :tenant_adapters, :tenants
    add_foreign_key :tenant_adapters, :adapters
    add_index :tenant_adapters, [:tenant_id, :adapter_id]
    add_index :tenant_adapters, [:adapter_id, :tenant_id]
  end
end
