class RemoveAdapterRefFromGCPServiceForecastCost < ActiveRecord::Migration[5.1]
  def change
    remove_reference :gcp_service_forecast_costs, :adapter
    add_column :gcp_service_forecast_costs, :adapter_id, :uuid
  end
end
