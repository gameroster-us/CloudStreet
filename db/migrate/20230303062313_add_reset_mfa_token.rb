class AddResetMfaToken < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :reset_mfa_token, :text
    add_column :users, :reset_mfa_sent_at, :datetime
  end
end
