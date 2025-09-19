class AddFieldsToUserPreferences < ActiveRecord::Migration[5.1]
  def change
    add_column :user_preferences, :prefereable_id, :uuid
    add_column :user_preferences, :prefereable_type, :string
  end
end
