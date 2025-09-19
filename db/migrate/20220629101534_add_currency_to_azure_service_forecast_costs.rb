class AddCurrencyToAzureServiceForecastCosts < ActiveRecord::Migration[5.1]
  def change
    add_column :azure_service_forecast_costs, :currency, :string
  end
end
