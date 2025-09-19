class AddCurrencyToAzureRgServiceForecastCosts < ActiveRecord::Migration[5.1]
  def change
    add_column :azure_rg_service_forecast_costs, :currency, :string
  end
end
