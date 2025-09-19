class AddIndexToSubscription < ActiveRecord::Migration[5.1]
  def up
  	add_index :subscriptions, :adapter_id unless index_exists?(:subscriptions, :adapter_id)
  	add_index :subscriptions, :id unless index_exists?(:subscriptions, :id)
  end

  def up
  	remove_index :subscriptions, :adapter_id if index_exists?(:subscriptions, :adapter_id)
  	remove_index :subscriptions, :id if index_exists?(:subscriptions, :id)
  end
end
