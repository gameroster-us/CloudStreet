class AddColumnsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :mfa_enabled, :boolean, default: false
    add_column :users, :google_secret, :string
    add_column :users, :salt, :string
  end
end
