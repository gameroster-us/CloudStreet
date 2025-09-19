class AddScopeToAzureExportConfigurations < ActiveRecord::Migration[5.1]
  def change
    add_column :azure_export_configurations, :scope, :string, default: 'Subscription'
    add_column :azure_export_configurations, :billing_account_id, :string
  end
end
