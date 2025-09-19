# frozen_string_literal: true

# authorizing service now integrations actions
class Integrations::ServiceNow::ServiceNowTemplates::Budget::Template
  def self.account_budget_limit_crossed(info, header = '')
    { 'short_description' => header, 'description' => "You requested that we alert you when the cost associated with your budget exceeds #{info[:currency]} #{info[:max_amount]} for the current month. The current cost for your cloud account linked with CloudStreet is #{info[:currency]} #{info[:cost_to_date]}\nName:  #{info[:budget_name]} \nTenant: #{info[:tenant_name]} \nMonthly Budget:  #{info[:currency]} #{info[:max_amount]} \nCost To Date:  #{info[:currency]} #{info[:cost_to_date]}", 'urgency' => '1', 'impact' => '1' }
  end

  def self.threshold_limit_crossed(info, header = '')
    { 'short_description' => header, 'description' => "You requested that we alert you when the cost associated with your Budget exceeds the threshold limit of #{info[:threshold_value]}% for the current month. The current cost for your cloud account linked with CloudStreet is #{info[:currency]} #{info[:cost_to_date]}.\nName:  #{info[:budget_name]} \nTenant: #{info[:tenant_name]} \nMonthly Budget:  #{info[:currency]} #{info[:max_amount]} \nCost To Date:  #{info[:currency]} #{info[:cost_to_date]}", 'urgency' => '1', 'impact' => '1' }
  end
end
