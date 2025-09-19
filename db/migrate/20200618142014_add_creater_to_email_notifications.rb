class AddCreaterToEmailNotifications < ActiveRecord::Migration[5.1]
  def change
    add_column :email_notifications, :creater, :uuid
  end
end
