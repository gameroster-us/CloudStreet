class AddBillingAdapterColumnToServiceGroupCost < ActiveRecord::Migration[5.2]
  def change
    add_column :service_group_costs, :billing_adapter_id, :uuid
    add_index :service_group_costs, [:tenant_id, :service_group_id]
    # In Next Release we need to add index on bcuz right now billing adapter id is now null.
    # tenan_id & billing_adapter_id & service_group_name
  end
end
