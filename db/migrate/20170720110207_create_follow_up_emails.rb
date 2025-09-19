class CreateFollowUpEmails < ActiveRecord::Migration[5.1]
  def change
    create_table :follow_up_emails, id: :uuid do |t|
      t.uuid :user_id
      t.uuid :account_id
      t.string :followup_for
      t.boolean :status, default: true
      t.datetime :start_at, :default => Time.now
      t.datetime :finish_at

      t.timestamps
    end
    add_index :follow_up_emails, :user_id
    add_index :follow_up_emails, :account_id
    add_foreign_key(:follow_up_emails, :users, column: 'user_id', on_delete: :cascade)
    add_foreign_key(:follow_up_emails, :accounts, column: 'account_id', on_delete: :cascade)
  end
end
