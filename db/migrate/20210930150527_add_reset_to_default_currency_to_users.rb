class AddResetToDefaultCurrencyToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :reset_to_default_currency, :boolean
  end
end
