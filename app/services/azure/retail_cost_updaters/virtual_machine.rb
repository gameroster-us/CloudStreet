# frozen_string_literal: false

module Azure
  module RetailCostUpdaters
    # Service to fetch retail price and update
    # cost_by_hour of non reserved vms
    class VirtualMachine < Azure::RetailCostUpdater
      attr_reader :region_retail_prices, :vm_object, :sku_retail_price

      def set_region_retail_prices!
        @region_retail_prices = Azure::RetailPriceList.where(region_code: @region.code)
                                                      .virtual_machine_prices
                                                      .first
      end

      def pre_conditions_passed?
        !(resource_object.reserved_vm? || resource_object.cost_by_hour.positive? || resource_object.stopped_deallocated?)
      end

      private

      def set_sku_retail_price!
        @sku_retail_price = region_retail_prices&.select_by_vm_sku(resource_object.vm_size) || []
        filter_price_attributes # Filter region retail price with matching attributes
        # determine_cost_by_os_type # Finding actual retail price for that VM
      end

      def filter_price_attributes
        @sku_retail_price.select! do |retail_price|
          !retail_price['meterName'].downcase.include?('spot') &&
            !retail_price['meterName'].downcase.include?('low priority') &&
            !retail_price['type'].downcase.eql?('reservation')
        end
      end

      def set_cost_by_hour!
        vm_price_detail = if resource_object.windows_vm?
                            sku_retail_price.find { |retail_price| retail_price['productName'].downcase.include?('windows') }
                          else
                            sku_retail_price.find { |retail_price| !retail_price['productName'].downcase.include?('windows') }
                          end
        @cost_by_hour = vm_price_detail.try(:[], 'retailPrice').try(:to_f)
      end
    end
  end
end
