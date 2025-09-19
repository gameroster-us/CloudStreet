class AddAdapterIdToEmailNotifications < ActiveRecord::Migration[5.1]
  def change
    add_column :email_notifications, :adapter_id, :uuid
  end
end
