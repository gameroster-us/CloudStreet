class CreateAzureRgServiceForecastCosts < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_rg_service_forecast_costs, id: :uuid do |t|
      t.string :subscription_id
      t.uuid :adapter_id
      t.string :tab
      t.float :cost
      t.references :account, type: :uuid, foreign_key: true

      t.timestamps
    end
  end
end
