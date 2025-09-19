class DashboardData < ApplicationRecord
  belongs_to :account

  def self.get_charts_data(account)
  	dashboard_data = DashboardData.select("name,data").where(account_id: account.id).all
  end
end
