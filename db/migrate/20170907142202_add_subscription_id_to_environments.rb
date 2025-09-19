class AddSubscriptionIdToEnvironments < ActiveRecord::Migration[5.1]
  def change
    add_column :environments, :subscription_id, :uuid
    add_foreign_key(:environments, :subscriptions, column: 'subscription_id', on_delete: :cascade)
    add_index :environments, :subscription_id
  end
end
