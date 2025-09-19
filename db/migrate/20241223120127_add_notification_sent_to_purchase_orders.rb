class AddNotificationSentToPurchaseOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :purchase_orders, :notification_sent, :boolean, default: false
  end
end
