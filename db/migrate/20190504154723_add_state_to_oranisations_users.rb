class AddStateToOranisationsUsers < ActiveRecord::Migration[5.1]
  def change
  	add_column :organisations_users, :uuid, :primary_key
  	add_column :organisations_users, :state, :string, :default => "invited"
  	add_column :organisations_users, :invite_token, :string
  	add_column :organisations_users, :invited_at, :timestamp
  end
end
