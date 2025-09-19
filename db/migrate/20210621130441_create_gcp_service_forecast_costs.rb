class CreateGCPServiceForecastCosts < ActiveRecord::Migration[5.1]
  def change
    create_table :gcp_service_forecast_costs, id: :uuid do |t|
      t.string :billing_account_id
      t.string :tab
      t.float :cost
      t.references :account, type: :uuid, foreign_key: true
      t.references :adapter, type: :uuid, foreign_key: true

      t.timestamps
    end
  end
end
