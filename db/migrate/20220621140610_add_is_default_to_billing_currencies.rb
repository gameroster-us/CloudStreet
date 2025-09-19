class AddIsDefaultToBillingCurrencies < ActiveRecord::Migration[5.1]
  def change
    add_column :billing_currencies, :is_default, :boolean, default: false
  end
end
