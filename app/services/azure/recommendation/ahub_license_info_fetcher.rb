# frozen_string_literal: false

module Azure
  module Recommendation
    # Module contains specic methods to fetch license cost
    # for different subscriptions
    module AhubLicenseInfoFetcher
      VM_LICENSE_METER_CATEGORY = 'Virtual Machines Licenses'.freeze
      DEFAULT_CURRENCY_CONVERSION = 'USD'

      private

      def set_license_cost!
        @license_cost = if adapter.csp_adapter?
                          fetch_license_info_for_csp_adapter
                        elsif adapter.china_adapter?
                          fetch_license_info_for_china_adapter
                        elsif adapter.ea_adapter?
                          fetch_license_info_for_ea_adapter
                        else
                          fetch_license_info_for_payg_adapter
                        end
      end

      # Use billing meter data saved from athena
      def fetch_license_info_for_csp_adapter
        license_cost_from_meter
      end

      # Use billing meter data saved from athena
      def fetch_license_info_for_china_adapter
        license_cost_from_meter
      end

      # Use billing meter data savedfrom athena
      # Or pricesheet data from Azure::PriceSheet table
      def fetch_license_info_for_ea_adapter
        return fetch_license_info_for_payg_ea_adapter_sql_server_with_windows_server if @vm_instance.is_sql_server_with_window_server

        has_license_meter = @vm_instance.meter_data.any? { |meter| meter['meter_category'].downcase.eql?(VM_LICENSE_METER_CATEGORY.downcase) }
        if has_license_meter
          license_cost_from_meter
        else
          license_cost_from_ea_pricesheet(true)
        end
      end

      # Use rate card or retail cost for standard PAYG subscription.
      # If we don't get license cost from rate card then we fetch
      # The non-windows (only compute cost) cost of the vm sku from retail price
      def fetch_license_info_for_payg_adapter
        return fetch_license_info_for_payg_ea_adapter_sql_server_with_windows_server if @vm_instance.is_sql_server_with_window_server

        license_meter = @vm_instance.meter_data.find { |meter| meter['meter_category'].downcase.eql?(VM_LICENSE_METER_CATEGORY.downcase) }
        if license_meter.present?
          calculate_cost_from_rate_card(license_meter['meter_id'])
        else
          calculate_cost_from_retail_price_payg_adapter(true) # subtract_from_total_vm_cost
        end
      rescue StandardError => e
        CSLogger.error "==== AhubLicenseInfoFetcher :  Something went wrong while fetching license cost for PAYG --- Error: #{e.message} ===="
        0.0
      end

      # Resource rate of EA/China/CSP is Billing Currency Specific.
      # So we need to covert the resource_rate value to it's equivalent
      # USD value
      def license_cost_from_meter
        license_meter = @vm_instance.meter_data.find { |meter| meter['meter_category'].downcase.eql?(VM_LICENSE_METER_CATEGORY.downcase) }
        return 0.0 if license_meter.nil?

        license_meter['resource_rate'].to_f * (CurrencyConverter.get_converted_price(@vm_instance.data['currency'], DEFAULT_CURRENCY_CONVERSION) || 1)
      end

      def license_cost_from_ea_pricesheet(subtract_from_total_vm_cost)
        @regional_pricesheet = @pricesheet.where(region_code: @vm_instance.region_code).first.try(:prices) || []
        calculate_license_cost_from_region_pricesheet(subtract_from_total_vm_cost)
      rescue StandardError => e
        CSLogger.error "==== AhubLicenseInfoFetcher :  Something went wrong while fetching license cost from PriceSheet --- Error: #{e.message} ===="
        0.0
      end

      # Return the price difference between windows and non-windows as license price
      def calculate_license_cost_from_region_retail_price(subtract_from_total_vm_cost)
        return 0.0 unless @sku_regional_retail_prices.is_a? Array

        return 0.0 if @sku_regional_retail_prices.empty?

        non_windows_price_details = @sku_regional_retail_prices.find do |sku_retail_price|
          !sku_retail_price['productName'].downcase.include?('windows') &&
            !sku_retail_price['meterName'].downcase.include?('spot') &&
            !sku_retail_price['meterName'].downcase.include?('low priority') &&
            !sku_retail_price['type'].downcase.eql?('reservation')
        end
        non_windows_hourly_cost = non_windows_price_details.try(:[], 'retailPrice').try(:to_f) || 0.0
        return 0.0 unless non_windows_hourly_cost.positive?

        subtract_from_total_vm_cost ? @vm_instance.cost_by_hour - non_windows_hourly_cost : non_windows_hourly_cost
      end

      # Identify the infrustructure cost of the vm_sku from EA pricesheet.
      # Subtract the infrustructure cost from original VM cost, to get only license cost
      def calculate_license_cost_from_region_pricesheet(subtract_from_total_vm_cost)
        return 0.0 unless @regional_pricesheet.is_a? Array

        return 0.0 if @regional_pricesheet.blank?

        vm_original_size = @vm_instance.vm_size.split('_')[1..-1].join('_').downcase
        vm_formatted_size = vm_original_size.present? ? vm_original_size.try(:tr, '_', ' ') : ''
        non_windows_price_details = @regional_pricesheet.find do |meter|
          meter_details = meter['meterDetails']
          meter_name = meter_details['meterName'].downcase
          (meter_name.include?(vm_original_size) || meter_name.include?(vm_formatted_size)) &&
            !meter_details['meterSubCategory'].include?('Windows') &&
            !meter_name.include?(Azure::PriceSheet::LOW_PRIORITY.try(:downcase))
        end
        non_windows_hourly_cost = self.class.calulate_pricesheet_cost_by_hour(non_windows_price_details, @vm_instance.data['currency'])
        return 0.0 unless non_windows_hourly_cost.positive?

        subtract_from_total_vm_cost ? @vm_instance.cost_by_hour - non_windows_hourly_cost : non_windows_hourly_cost
      end

      # This is cost we are calculating from retal price to get the compute cost without license
      def calculate_cost_from_retail_price_payg_adapter(subtract_from_total_vm_cost)
        @sku_regional_retail_prices = @vm_retail_prices.where(region_code: @vm_instance.region_code)
                                               .first&.select_by_vm_sku(@vm_instance.vm_size)
        calculate_license_cost_from_region_retail_price(subtract_from_total_vm_cost)
      end

      def calculate_sql_license_cost
        sql_meter_data = @vm_instance.meter_data.find {|meter_data| meter_data['meter_category'] == VM_LICENSE_METER_CATEGORY && (meter_data['meter_sub_category'].include?('SQL Server') ||  meter_data['service_tier'].include?('SQL Server')) }
        return nil unless sql_meter_data.present?

        if adapter.ea_adapter?
          sql_meter_data['resource_rate'].to_f * (CurrencyConverter.get_converted_price(@vm_instance.data['currency'], DEFAULT_CURRENCY_CONVERSION) || 1)
        else
          calculate_cost_from_rate_card(sql_meter_data['meter_id'])
        end
      end

      def calculate_cost_from_rate_card(meter_id)
        license_rate = rate_card.find { |rate_detail| rate_detail['MeterId'].eql?(meter_id) }
        license_rate.try(:[], 'MeterRates').try(:[], '0') || 0.0
      end

      # For Microsoft SQL server i.e Sql Server with Windows Server
      def fetch_license_info_for_payg_ea_adapter_sql_server_with_windows_server
        return 0.0 if @vm_instance.sql_virtual_machine.empty? # It might be possible sql virtual machine will be 0 due to forbidden error in api
        return 0.0 unless @vm_instance.meter_data.any? # we are not recomending for the retail price that why sending 0.0

        # Get Imp data for calcualting license cost
        vm_compute_without_license_cost = calculate_cost_vm_without_license_cost_sql_server_with_windows_server
        vm_sql_license_cost = calculate_sql_license_cost

        # There are 3 sceanrios
        # 1st => Both contain license
        if (!@vm_instance.provider_data.key?('license_type') || @vm_instance.provider_data['license_type'] == 'None') && !['AHUB', 'DR'].include?(@vm_instance.sql_virtual_machine['properties']['sqlServerLicenseType'])
          return 0.0 if vm_sql_license_cost.nil? # If vm_sql_license_cost is nil, so we cant calculate the license cost

          # Here getting only vm license cost
          vm_license_cost = @vm_instance.cost_by_hour - ( vm_compute_without_license_cost + vm_sql_license_cost )
          vm_license_cost + vm_sql_license_cost # Both licesnse cost gets added

        # 2nd => Only Virtual Machine having AHUB enable
        elsif @vm_instance.provider_data.key?('license_type') && @vm_instance.provider_data['license_type'] != 'None'
          # return 0.0 if vm_sql_license_cost.nil? # If vm_sql_license_cost is nil, so we cant calculate the license cost
          vm_sql_license_cost.nil? ? @vm_instance.cost_by_hour - vm_compute_without_license_cost : vm_sql_license_cost

        # 3rd => Only SQL Server AHUB OR DR enable
        elsif ['AHUB', 'DR'].include? @vm_instance.sql_virtual_machine['properties']['sqlServerLicenseType']
          @vm_instance.cost_by_hour - vm_compute_without_license_cost

        # Just handled for sceanrio which might be missed
        else
          0.0
        end
      end

      def calculate_cost_vm_without_license_cost_sql_server_with_windows_server
        if adapter.ea_adapter?
          license_cost_from_ea_pricesheet(false)
        else
          calculate_cost_from_retail_price_payg_adapter(false) # subtract_from_total_vm_cost is a false
        end
      end
    end
  end
end
