class CreateAdminUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :admin_users do |t|
      t.string :name
      t.string :email
      t.string :username
      t.string :api_token
      t.string :password_digest
      t.string :reset_password_token
      t.datetime :reset_password_sent_at


      t.timestamps
    end
  end
end