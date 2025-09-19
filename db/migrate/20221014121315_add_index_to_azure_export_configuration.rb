class AddIndexToAzureExportConfiguration < ActiveRecord::Migration[5.1]
  def change
    add_column :azure_export_configurations, :index, :integer, unique: true
    add_column :azure_export_configurations, :is_editable, :boolean, default: true
    add_column :azure_export_configurations, :is_deleted, :boolean, default: false
  end
end