class AddDataToUserNotifications < ActiveRecord::Migration[5.1]
  def change
  	remove_column :user_notifications, :text ,:string
    add_column :user_notifications, :data, :json
  end
end
