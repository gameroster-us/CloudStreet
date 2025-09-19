module Trackable
  extend ActiveSupport::Concern

  thread_mattr_accessor :browser, :ip_address, :controller, :action_name, :status, :user, :account_id, :current_tenant_id, :res_status

  included do
    attr_accessor :change_logs, :save_activity
    after_save :record_user_activity
  end

  def record_user_activity
    self.change_logs = self.change_logs.present? ? self.change_logs.merge(self.changes) : self.changes
    previous_client = Thread.current[:client_db]
    if Trackable.user.present? && ![422, 500].include?(Trackable.res_status) && (self.save_activity.present? ||  Trackable.action_name == 'destroy')
      Thread.current[:client_db] = 'api_default'
      options = {
        browser: Trackable.browser,
        ip_address: Trackable.ip_address,
        controller: Trackable.controller,
        action_name: Trackable.action_name,
        status: Trackable.status,
        user: Trackable.user,
        name: self.name,
        account_id: Trackable.account_id,
        current_tenant_id: Trackable.current_tenant_id,
        log_data: self.change_logs
      }
      activity = UserActivity.init_activity(options)
      activity.save
    end
    Thread.current[:client_db] = previous_client
  end

  def set_month_percentage
    self['current_month'] =  self.monthly_cost_to_date.try(:first).blank? ? 0.0 : self.monthly_cost_to_date.first.include?(Date.today.strftime('%b %Y')) ? self.monthly_cost_to_date.first.select { |k, v| v if k.include?(Date.today.strftime('%b %Y')) }.values.first.to_f : 0.0
    self['current_month_percentage'] = (self['current_month'] / self.max_amount.to_f) * 100
    self['previous_month_percentage'] = (self['current_month'] / self.prev_month.to_f) * 100
    self['forecast_percentage'] = (self['forecast'].to_f / self.max_amount.to_f) * 100
    self['total_balance'] = (self.max_amount.to_f - self['forecast'].to_f)
    self['over_budget'] = self.state.eql?('limit_crossed')
    self['threshold_budget'] = self.state.eql?('threshold_limit')
    self['threshold_alerts'] = VmWareBudgetService.threshold_alerts_values(self) if self.state.eql?('threshold_limit')
  end

end
