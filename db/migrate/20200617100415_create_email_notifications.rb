class CreateEmailNotifications < ActiveRecord::Migration[5.1]
  def change
    create_table :email_notifications, id: :uuid do |t|
      t.string :name
      t.boolean :notify, default: false
      t.boolean :notify_using_tag, default: false
      t.boolean :append_domain, default: false
      t.string :custom_emails, array: true, default: []
      t.string :notification_roles, array: true, default: []
      t.string :notification_users, array: true, default: []
      t.json :notify_condition, default: {}
      t.string :service_ids, array: true, default: []
      t.string :type
      t.uuid :account_id

      t.timestamps
    end
  end
end
