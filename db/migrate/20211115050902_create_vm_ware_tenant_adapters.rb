class CreateVmWareTenantAdapters < ActiveRecord::Migration[5.1]
  def change
    create_table :vm_ware_tenant_adapters, id: :uuid do |t|
      t.references :organisation, foreign_key: true, type: :uuid
      t.references :tenant, foreign_key: true, type: :uuid
      t.uuid :adapter_id

      t.timestamps
    end
  end
end