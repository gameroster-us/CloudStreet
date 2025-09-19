# frozen_string_literal: false

module Azure
  module RetailCostUpdaters
    # Service to fetch retail price and update
    # cost_by_hour of non reserved vms
    class AppServicePlan < Azure::RetailCostUpdater
      attr_reader :region_retail_prices, :sku_retail_price, :cost_by_hour

      def set_region_retail_prices!
        @region_retail_prices = Azure::RetailPriceList.where(region_code: @region.code)
                                                      .app_service_plan
                                                      .first
      end

      def pre_conditions_passed?
        !resource_object.cost_by_hour.positive?
      end

      private

      def set_sku_retail_price!
        @sku_retail_price = region_retail_prices&.select_by_app_service_plan_meter_name(resource_object.sku) || []
        filter_price_attributes
      end

      def filter_price_attributes
        @sku_retail_price.select! do |retail_price|
          retail_price['type'].downcase.eql?('consumption')
        end
      end

      def set_cost_by_hour!
        vm_price_detail = if resource_object.is_linux?
                            sku_retail_price.find { |retail_price| retail_price['productName'].downcase.include?('linux') }
                          else
                            sku_retail_price.find { |retail_price| !retail_price['productName'].downcase.include?('linux') }
                          end
        vm_price_detail_price = vm_price_detail.try(:[], 'retailPrice').try(:to_f)
        if vm_price_detail_price.nil?
          @cost_by_hour = 0.0
          return
        end

        @cost_by_hour = vm_price_detail_price * resource_object.sku['capacity']
      end
    end
  end
end
