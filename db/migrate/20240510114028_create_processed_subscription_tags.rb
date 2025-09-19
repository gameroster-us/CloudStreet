class CreateProcessedSubscriptionTags < ActiveRecord::Migration[5.2]
  def change
    create_table :processed_subscription_tags, id: :uuid do |t|
      t.text :subscription_tags, array: true, default: []
      t.string :adapter_id

      t.timestamps
    end
  end
end
