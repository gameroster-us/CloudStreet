# frozen_string_literal: false

module Azure
  module RetailCostUpdaters
    # Service class to add retail cost
    # For disk missing cost_by_hour
    class AKS < Azure::RetailCostUpdater
      attr_reader :region_retail_prices, :sku_retail_price

      def set_region_retail_prices!
        @region_retail_prices = Azure::RetailPriceList.where(region_code: @region.code)
                                                      .azure_kubernetes_service
                                                      .first
      end

      def pre_conditions_passed?
        true
      end

      private

      def set_sku_retail_price!
        @sku_retail_price = region_retail_prices&.select_by_meter_name() || []
        # Filter region retail price with matching attributes
        # determine_cost_by_os_type # Finding actual retail price for that VM
      end

      def set_cost_by_hour!
        @cost_by_hour = sku_retail_price.try(:[], 'retailPrice').try(:to_f)
      end
    end
  end
end
