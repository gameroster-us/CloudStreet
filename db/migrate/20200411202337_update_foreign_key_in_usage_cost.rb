class UpdateForeignKeyInUsageCost < ActiveRecord::Migration[5.1]
  def change
    remove_foreign_key(:azure_usage_costs, :subscriptions)
    add_foreign_key(:azure_usage_costs, :azure_subscriptions, column: 'subscription_id', on_delete: :cascade)
  end
end
