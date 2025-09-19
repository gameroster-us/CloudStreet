class AddResellerColumnsToAzureServiceForecastCosts < ActiveRecord::Migration[5.1]
  def change
    add_column :azure_service_forecast_costs, :reseller_org_net_cost, :float
  end
end
