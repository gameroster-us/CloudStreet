class AddShowIntroToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :show_intro, :boolean, default: true
  end
end
