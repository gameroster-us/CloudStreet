class CreateAzureTenantBillingAdapters < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_tenant_billing_adapters, id: :uuid do |t|
      t.uuid :organisation_id
      t.uuid :tenant_id
      t.uuid :billing_adapter_id

      t.timestamps
    end
  end
end
