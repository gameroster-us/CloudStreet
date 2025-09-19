class CreateFollowUpEmailHistories < ActiveRecord::Migration[5.1]
  def change
    create_table :follow_up_email_histories, id: :uuid do |t|
      t.uuid :follow_up_email_id
      t.datetime :scheduled_at
      t.datetime :processed_at
      t.boolean :status, default: false
      t.boolean :process_status

      t.timestamps
    end
    add_index :follow_up_email_histories, :follow_up_email_id
    add_foreign_key(:follow_up_email_histories, :follow_up_emails, column: 'follow_up_email_id', on_delete: :cascade)
  end
end
