class ChangeJsonToDefaultInUserPreferences < ActiveRecord::Migration[5.1]
  def change
    change_column :user_preferences, :preferences, :json

    execute "ALTER TABLE user_preferences ALTER COLUMN preferences SET DEFAULT '{}'"
    execute "UPDATE user_preferences SET preferences = '{}';"
  end
end
