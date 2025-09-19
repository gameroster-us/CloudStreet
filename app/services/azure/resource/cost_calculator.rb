module Azure::Resource::CostCalculator
  def self.included(receiver)
    module_name = "Azure::Resource::CostCalculators#{receiver.to_s.split('Resource').last}".constantize rescue nil
    receiver.include module_name unless module_name.blank?
  end

  def calculate_hourly_cost(meter_data = nil)
    0.0
  end

  def set_hourly_cost
    self.cost_by_hour = calculate_hourly_cost
    self.additional_properties['price_type'] = ''
    self.data.merge!("storage_sub_account_costs" => calculate_hourly_cost_for_individual_account) if self.class.name.eql?("Azure::Resource::StorageAccount")
  end
end
