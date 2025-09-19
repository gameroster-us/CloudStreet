class AddMiraToUserRole < ActiveRecord::Migration[5.2]
  def change
    add_column :user_roles, :mira, :boolean, default: false
  end
end
