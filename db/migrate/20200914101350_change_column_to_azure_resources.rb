class ChangeColumnToAzureResources < ActiveRecord::Migration[5.1]
  def change
  	remove_column :azure_resources, :meter_data, :jsonb, default: {}
  	add_column :azure_resources, :meter_data, :json, array: true, default: []
  end
end
