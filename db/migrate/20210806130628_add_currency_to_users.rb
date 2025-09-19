class AddCurrencyToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :override_tenant_currency, :boolean
    add_column :users, :default_currency, :string
  end
end
