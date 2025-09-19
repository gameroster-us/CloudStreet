class CreateVmWareServiceForecastCosts < ActiveRecord::Migration[5.1]
  def change
    create_table :vm_ware_service_forecast_costs, id: :uuid do |t|
      t.references :adapter, foreign_key: true, type: :uuid
      t.references :account, foreign_key: true, type: :uuid
      t.string :month
      t.string :tab
      t.float :cost

      t.timestamps
    end
  end
end
