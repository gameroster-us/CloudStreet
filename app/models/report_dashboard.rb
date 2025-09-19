# Report Dashboard
class ReportDashboard
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  store_in client: -> { CurrentAccount.client_db }

  def self.get_current_month_account_data
    data = where(type: 'current_month_cost_by_all_account').last
    return [] if data.blank?
    data.chart_data[:categories].last[:category]
  end
end
