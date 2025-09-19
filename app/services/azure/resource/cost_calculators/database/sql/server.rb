# frozen_string_literal: true
module Azure::Resource::CostCalculators::Database::SQL::Server
  DEFAULT_CURRENCY_CONVERSION = 'USD'

  def calculate_hourly_cost
    self.meter_data.reject! { |meter| meter['unit'].nil? } if adapter.ea_adapter?
    actual_cost_meter_data = self.meter_data
    self.meter_data = self.meter_data.uniq { |cost| cost['meter_id'] }.map { |cost| cost.slice("resource_name", "service_name", "service_tier", "meter_id", "instance_id", "pre_tax_cost", "resource_rate","meter_name", "meter_category", "meter_sub_category", "meter_region", "usage_date_time", "quantity", "unit") }
    if adapter.azure_cloud.eql?("AzureChinaCloud")
      filter_parameters_arr = ['Hours','GB/Month', 'Day']
      update_actual_cost(actual_cost_meter_data, filter_parameters_arr)
      total_hourly_cost = meter_data.inject(0) do |result, meter|
        hourly_cost = 0
        if meter.present?
          rate = meter["resource_rate"].to_f || 0.0
          hourly_cost =
            if meter["unit"].eql?("Hours")
              rate
            elsif meter["unit"].eql?("GB/Month")
              (rate / (24 * 30)) * ((storage_size_in_mb || 1) / 1024)
            elsif meter["unit"].eql?("Day")
              (rate / 24)
            else
              CSLogger.info "meter unit #{meter['unit']} not set for #{self.class.name}"
              0.0
            end
        end
        result + hourly_cost
      end
      total_hourly_cost * CurrencyConverter.get_converted_price(data['currency'],DEFAULT_CURRENCY_CONVERSION)

    elsif adapter.csp_adapter? 
      filter_parameters_arr = ['1 Hours','1 GB/Month', '1/Day']
      update_actual_cost(actual_cost_meter_data, filter_parameters_arr)
      total_hourly_cost = meter_data.inject(0) do |result, meter|
        hourly_cost = 0
        if meter.present?
          rate = meter["resource_rate"].to_f || 0.0
          hourly_cost =
            if meter["unit"].eql?("1 Hours")
              rate
            elsif meter["unit"].eql?("1 GB/Month")
              (rate / (24 * 30)) * ((storage_size_in_mb || 1) / 1024)
            elsif meter["unit"].eql?("1/Day")
              (rate / 24)
            else
              CSLogger.info "meter unit #{meter['unit']} not set for #{self.class.name}"
              0.0
            end
        end
        result + hourly_cost
      end
      total_hourly_cost * CurrencyConverter.get_converted_price(data['currency'], DEFAULT_CURRENCY_CONVERSION)

    elsif adapter.ea_adapter?
      filter_parameters_arr = ['Hours','GB/Month', '/Day']
      update_actual_cost(actual_cost_meter_data, filter_parameters_arr)
      total_hourly_cost = meter_data.inject(0) do |result, meter|
        hourly_cost = 0
        if meter.present?
          rate = meter["resource_rate"].to_f || 0.0
          hourly_cost =
            if meter["unit"].include?("Hours")
              rate
            elsif meter["unit"].include?("GB/Month")
              (rate / (24 * 30)) * ((storage_size_in_mb || 1) / 1024)
            elsif meter["unit"].include?("/Day")
              (rate / 24)
            else
              CSLogger.info "meter unit #{meter['unit']} not set for #{self.class.name}"
              0.0
            end
        end
        result + hourly_cost
      end
      total_hourly_cost * CurrencyConverter.get_converted_price(data['currency'], DEFAULT_CURRENCY_CONVERSION)

    else
      rate_card = Azure::AzureResourceRateCard.where(subscription_id: subscription_id, category: 'general', :region_code.in => [Rightsizings::Azure::AzurePricelistFetcher::REGION_MAP[region_code], "", nil]).map(&:rates).flatten
      return 0.0 unless rate_card.present?

      total_hourly_cost = meter_data.inject(0) do |result, meter|
        hourly_cost = 0
        meter_details = (rate_card || []).find { |data| data["MeterId"].eql?(meter['meter_id']) }
        if meter_details.present?
          rate = meter_details.present? ? meter_details.try(:[], "MeterRates").try(:[], "0") || 0.0 : 0.0
          hourly_cost =
            if meter_details["Unit"].eql?("1 Hour")
              rate
            elsif meter_details["Unit"].eql?("1 GB/Month")
              (rate / (24 * 30)) * ((storage_size_in_mb || 1) / 1024)
            elsif meter_details["Unit"].eql?("1/Day")
              (rate / 24)
            else
              CSLogger.info "meter unit #{meter_details['Unit']} not set for #{self.class.name}"
              0.0
            end
        end
        result + hourly_cost
      end
      total_hourly_cost
    end
  end
  def update_actual_cost(actual_cost_meter_data, filter_parameters_arr)
    actual_cost_meter_data = actual_cost_meter_data.select{|data| self.meter_data.pluck('meter_id').include?(data['meter_id']) }
    actual_cost_meter_data = if adapter.ea_adapter?
      actual_cost_meter_data.select{|data| filter_parameters_arr.any?{|unit| data['unit'].include?(unit)} } 
    else
      actual_cost_meter_data.select{|data| filter_parameters_arr.include?(data['unit']) }
    end
    converted_actual_cost = (actual_cost_meter_data.map{|m| m['pre_tax_cost'].to_f.round(2)}.sum *  CurrencyConverter.get_converted_price(data['currency'], DEFAULT_CURRENCY_CONVERSION)
) || 0
    self.data.merge!(::Azure::Resource::USAGE_COST_KEY => converted_actual_cost)
  end
end
