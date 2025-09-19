class CreateSubscriptions < ActiveRecord::Migration[5.1]
  def change
    create_table :subscriptions, id: :uuid do |t|
      t.string :provider_subscription_id
      t.string :name
      t.string :state
      t.json :data
      t.json :provider_data
      t.boolean :enabled, :default => true
      t.uuid :adapter_id, index: true

      t.timestamps
    end
  end
end
