class AddProviderToCurrencyConfigurations < ActiveRecord::Migration[5.1]
  def change
    add_column :currency_configurations, :provider, :string
  end
end
