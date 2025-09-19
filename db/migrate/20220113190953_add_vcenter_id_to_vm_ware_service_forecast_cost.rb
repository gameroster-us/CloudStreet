class AddVcenterIdToVmWareServiceForecastCost < ActiveRecord::Migration[5.1]
  def change
    add_column :vm_ware_service_forecast_costs, :vcenter_id, :uuid
  end
end
