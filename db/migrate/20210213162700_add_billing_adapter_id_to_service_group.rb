class AddBillingAdapterIdToServiceGroup < ActiveRecord::Migration[5.1]
  def change
    add_column :service_groups, :billing_adapter_id, :uuid
  end
end
