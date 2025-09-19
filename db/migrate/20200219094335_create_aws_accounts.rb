class CreateAWSAccounts < ActiveRecord::Migration[5.1]
  def change
    create_table :aws_accounts, id: :uuid do |t|

      t.string :aws_account_id
      t.boolean :is_password_present
      t.boolean :allow_users_to_change_password
      t.boolean :expire_passwords
      t.boolean :hard_expiry
      t.integer :max_password_age
      t.integer :minimum_password_length
      t.integer :password_reuse_prevention
      t.boolean :require_lowercase_characters
      t.boolean :require_numbers
      t.boolean :require_symbols
      t.boolean :require_uppercase_characters 


      t.timestamps
    end
  end
end