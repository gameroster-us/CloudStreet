class CreateAppAccessSecrets < ActiveRecord::Migration[5.1]
  def change
    create_table :app_access_secrets, id: :uuid do |t|
      t.text      :encrypted_token
      t.text      :description
      t.integer   :token_expires, :limit => 1
      t.uuid      :user_id, index: true
      t.uuid      :organisation_id, index: true
      t.datetime  :last_used
      t.boolean   :enabled, default: true
      t.timestamps
    end

    add_foreign_key :app_access_secrets, :organisations, on_delete: :cascade
    add_foreign_key :app_access_secrets, :users, on_delete: :cascade
  end
end
