class RemoveForeignKeySubscription < ActiveRecord::Migration[5.1]
  def up
  	remove_foreign_key(:azure_rate_cards, :subscriptions)
  end

  def down
  	add_foreign_key(:azure_rate_cards, :subscriptions, column: 'subscription_id', on_delete: :cascade)
  end
end
