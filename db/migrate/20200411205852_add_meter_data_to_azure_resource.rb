class AddMeterDataToAzureResource < ActiveRecord::Migration[5.1]
  def change
    add_column :azure_resources, :meter_data, :jsonb, default: {}
  end
end
