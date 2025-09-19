class AddApplicationwiseMonthlyBudgetToGeneralSettings < ActiveRecord::Migration[5.1]
  def change
    add_column :general_settings, :applicationwise_monthly_budget, :boolean, default: true
  end
end
