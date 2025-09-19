class AddBillingStatsToAccountRegions < ActiveRecord::Migration[5.1]
  def change
    add_column :account_regions, :billing_stats, :json, :default => [].to_json
  end
end
