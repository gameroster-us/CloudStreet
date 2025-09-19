class CreateTenantBillingAdapters < ActiveRecord::Migration[5.1]
  def change
    create_table :tenant_billing_adapters, id: :uuid do |t|
      t.uuid :tenant_id
      t.uuid :organisation_id
      t.uuid :billing_adapter_id
      t.timestamps
    end
  end
end
