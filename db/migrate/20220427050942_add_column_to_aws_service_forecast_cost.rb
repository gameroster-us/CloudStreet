class AddColumnToAWSServiceForecastCost < ActiveRecord::Migration[5.1]
  def change
    add_column :aws_service_forecast_costs, :net_cost, :float
    add_column :aws_service_forecast_costs, :margin_cost, :float
    add_column :aws_service_forecast_costs, :discount_cost, :float
  end
end
