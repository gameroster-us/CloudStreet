class RemoveBillingAccountIdFromGCPServiceForecastCosts < ActiveRecord::Migration[5.1]
  def change
    remove_column :gcp_service_forecast_costs, :billing_account_id
  end
end
