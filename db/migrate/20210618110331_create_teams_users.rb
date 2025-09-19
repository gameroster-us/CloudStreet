class CreateTeamsUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :teams_users, id: :uuid do |t|
      t.uuid :account_id
      t.uuid :organisation_id
      t.uuid :workspace_id
      t.uuid :user_id
      t.string :access_token
      t.jsonb :user_details, default: {}
      t.jsonb :bot_data, default: {} #member_added
      t.jsonb :conversation_data, default: {}
      t.jsonb :user_data, default: {}
      t.string :service_url
      t.string :aad_object_id
      t.timestamps
    end
  end
end
