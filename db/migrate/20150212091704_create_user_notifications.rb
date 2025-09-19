class CreateUserNotifications < ActiveRecord::Migration[5.1]
  def change
    create_table :user_notifications, id: :uuid do |t|
			t.uuid :account_id,  index: true
			t.string :notification_type
			t.string :text
			t.boolean :viewed_status, default: false
			t.timestamps
    end
  end
end