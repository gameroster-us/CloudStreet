class CreateCurrencyConfigurations < ActiveRecord::Migration[5.1]
  def change
    create_table :currency_configurations, id: :uuid do |t|
      t.string :cloud_provider_currency
      t.string :default_currency
      t.json :exchange_rates
      t.references :organisation, type: :uuid, foreign_key: true

      t.timestamps
    end
  end
end
