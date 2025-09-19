class Alert < ActiveRecord::Migration[5.1]
  def change
  	drop_table :user_notifications
  	create_table :alerts, id: :uuid do |t|
      t.json :data
      t.boolean :read, default: false
      t.datetime :read_at
      t.string :alertable_type
      t.string :alert_type
      t.uuid :alertable_id, index: true

      t.timestamps
    end
  end
end
