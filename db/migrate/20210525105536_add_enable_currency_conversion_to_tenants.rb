class AddEnableCurrencyConversionToTenants < ActiveRecord::Migration[5.1]
  def change
    add_column :tenants, :enable_currency_conversion, :boolean
    add_column :tenants, :default_currency, :string
  end
end
