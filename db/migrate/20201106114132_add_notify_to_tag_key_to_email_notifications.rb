class AddNotifyToTagKeyToEmailNotifications < ActiveRecord::Migration[5.1]
  def change
    add_column :email_notifications, :notify_to_tag_key, :string
  end
end
