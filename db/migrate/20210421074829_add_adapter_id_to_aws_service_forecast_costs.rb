class AddAdapterIdToAWSServiceForecastCosts < ActiveRecord::Migration[5.1]
  def change
    add_column :aws_service_forecast_costs, :adapter_id, :uuid
  end
end
