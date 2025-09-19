class CreateAzureSubscriptionTags < ActiveRecord::Migration[5.2]
  def change
    create_table :azure_subscription_tags, id: :uuid do |t|
      t.uuid :adapter_id, index: true
      t.jsonb :tags, array: true, default: []
      t.string :subscription_id
      t.jsonb :historical_tags, default: []
      t.uuid :account_id
      t.timestamps
    end
  end
end
