class AddColumnToGCPServiceForecastCosts < ActiveRecord::Migration[5.1]
  def change
    add_column :gcp_service_forecast_costs, :month, :string
  end
end
