class AddErrorMessageToAzureExportConfigurations < ActiveRecord::Migration[5.1]
  def change
    add_column :azure_export_configurations, :error_message, :text, array: true, default: []
  end
end
