class AddRefreshTokenToTeamsUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :teams_users, :refresh_token, :string
  end
end
