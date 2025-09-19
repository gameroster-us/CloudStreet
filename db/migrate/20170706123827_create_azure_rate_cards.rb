class CreateAzureRateCards < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_rate_cards, id: :uuid do |t|
      t.json :rates
      t.uuid :subscription_id, :unique => true
      t.timestamps
    end
    add_foreign_key(:azure_rate_cards, :subscriptions, column: 'subscription_id', on_delete: :cascade)
  end
end