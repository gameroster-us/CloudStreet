class AddIndexToProcessedSubscriptionTags < ActiveRecord::Migration[5.2]
  def change
    add_index :processed_subscription_tags, :adapter_id
  end
end
