class AddEnableWelcomePopupToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :enable_welcome_popup, :boolean, default: true
  end
end
