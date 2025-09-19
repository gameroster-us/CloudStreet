class CreateUserPreferences < ActiveRecord::Migration[5.1]
  def change
    create_table :user_preferences, id: :uuid do |t|
      t.uuid :user_id
      t.json :preferences

      t.timestamps
    end
  end
end
