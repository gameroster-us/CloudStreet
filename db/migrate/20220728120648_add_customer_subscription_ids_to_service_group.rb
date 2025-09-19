class AddCustomerSubscriptionIdsToServiceGroup < ActiveRecord::Migration[5.1]
  def change
    add_column :service_groups, :customer_subscriptions, :string, array: true, default: []
  end
end
