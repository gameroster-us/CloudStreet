class AddResellerColumnsToAWSServiceForecastCosts < ActiveRecord::Migration[5.1]
  def change
    add_column :aws_service_forecast_costs, :reseller_org_net_cost, :float
  end
end
