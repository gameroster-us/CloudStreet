class AddScopeIdToAzureExportConfiguration < ActiveRecord::Migration[5.1]
  def change
    add_column :azure_export_configurations, :scope_id, :string
  end
end
