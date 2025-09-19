class AddResourceGroupToAzureRgServiceForecastCosts < ActiveRecord::Migration[5.1]
  def change
    add_column :azure_rg_service_forecast_costs, :resource_group, :string
  end
end
