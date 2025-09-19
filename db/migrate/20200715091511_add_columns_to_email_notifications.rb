class AddColumnsToEmailNotifications < ActiveRecord::Migration[5.1]
  def change
    add_column :email_notifications, :service_type, :string, array: true, default: []
    add_column :email_notifications, :severity, :string, array: true, default: []
  end
end
