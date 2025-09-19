class CreateAzureUsageCosts < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_usage_costs, id: :uuid do |t|
      t.timestamp :start_datetime
      t.timestamp :end_datetime
      t.json :aggregate_usage_cost
      t.uuid :subscription_id, :unique => true
      t.string :aggregation_granularity
      t.string :show_details
      t.string :api_version

      t.timestamps
    end
    add_foreign_key(:azure_usage_costs, :subscriptions, column: 'subscription_id', on_delete: :cascade)
  end
end