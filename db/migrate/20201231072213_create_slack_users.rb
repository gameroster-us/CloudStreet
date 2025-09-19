class CreateSlackUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :slack_users, id: :uuid do |t|
      t.uuid :organisation_id
      t.uuid :user_id
      t.uuid :workspace_id
      t.uuid :account_id
      t.string :access_token
      t.jsonb :auth_data, default: {}
      t.jsonb :data, default: {}

      t.timestamps
    end

    add_index :slack_users, :user_id
    add_index :slack_users, :organisation_id
    add_index :slack_users, :workspace_id
    add_index :slack_users, :access_token
  end
end
