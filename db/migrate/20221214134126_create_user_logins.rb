class CreateUserLogins < ActiveRecord::Migration[5.1]
  def change
    create_table :user_logins, id: :uuid do |t|
      t.references :organisation, type: :uuid, foreign_key: true
      t.references :user, type: :uuid, foreign_key: true
      t.string :user_type
      t.string :ip_address
      t.string :user_agent
      t.datetime :signed_in_at, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end
  end
end
