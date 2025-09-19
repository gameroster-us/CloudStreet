class AddTenantIdToEmailNotifications < ActiveRecord::Migration[5.1]
  def change
  	add_column :email_notifications, :tenant_id, :uuid
  end
end
