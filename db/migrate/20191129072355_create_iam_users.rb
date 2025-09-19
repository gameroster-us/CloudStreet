class CreateIamUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :iam_users, id: :uuid do |t|
      t.string :path
      t.string :user_name
      t.string :user_id
      t.string :arn
      t.datetime :create_date
      t.datetime :password_last_used
      t.string :permissions_boundary
      t.text :tags,array: true, default: []
      t.boolean :password_enabled
      t.datetime :password_last_changed
      t.datetime :password_next_rotation
      t.boolean :mfa_active
      t.boolean :access_key_1_active
      t.datetime :access_key_1_last_rotated
      t.datetime :access_key_1_last_used_date
      t.string :access_key_1_last_used_region
      t.string :access_key_1_last_used_service
      t.boolean :access_key_2_active
      t.datetime :access_key_2_last_rotated
      t.datetime :access_key_2_last_used_date
      t.string :access_key_2_last_used_region
      t.string :access_key_2_last_used_service
      t.boolean :cert_1_active
      t.datetime :cert_1_last_rotated
      t.boolean :cert_2_active
      t.datetime :cert_2_last_rotated
      t.string :aws_account_id
      t.timestamps
    end
  end
end
