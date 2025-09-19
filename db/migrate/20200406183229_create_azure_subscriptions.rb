class CreateAzureSubscriptions < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_subscriptions, id: :uuid do |t|
      t.string :display_name
      t.uuid   :subscription_id
      t.references :adapter, type: :uuid, foreign_key: true
      t.json :subscription_policies
      t.string :authorization_source
      t.string :state

      t.timestamps
    end
  end
end
