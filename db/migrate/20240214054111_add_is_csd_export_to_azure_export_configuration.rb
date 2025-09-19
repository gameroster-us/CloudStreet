class AddIsCsdExportToAzureExportConfiguration < ActiveRecord::Migration[5.2]
  def change
    add_column :azure_export_configurations, :is_csd_export, :boolean, default: true
  end
end
