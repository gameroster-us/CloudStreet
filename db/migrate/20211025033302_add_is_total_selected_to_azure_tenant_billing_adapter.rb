class AddIsTotalSelectedToAzureTenantBillingAdapter < ActiveRecord::Migration[5.1]
  def change
    add_column :azure_tenant_billing_adapters, :is_total_selected, :boolean, default: false
  end
end
