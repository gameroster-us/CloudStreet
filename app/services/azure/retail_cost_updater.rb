# frozen_string_literal: true

module Azure
  # Service to add retail cost
  class RetailCostUpdater
    attr_reader :region, :resource_object, :region_retail_prices, :sku_retail_price, :cost_by_hour

    def initialize(region_id, resources)
      @region = Region.find(region_id)
      @azure_resources = resources
      set_region_retail_prices!
    end

    def start_updating
      @azure_resources.each do |resource|
        @resource_object = resource
        update_cost if pre_conditions_passed?
        CSLogger.info " ===== Adding Retail cost to Azure resource -- #{resource_object.name} of type - #{resource_object.type} ====="
      end
    end

    private

    def update_cost
      return if resource_object.cost_by_hour&.positive?

      begin
        set_sku_retail_price! if region_retail_prices.present?
        if sku_retail_price.present?
          set_cost_by_hour!
          update_resource_object
        end
      rescue StandardError => e
        CSLogger.error e.message
        CSLogger.error e.backtrace
      end
    end

    def update_resource_object
      resource_object.cost_by_hour = cost_by_hour
      resource_object.additional_properties.merge!(price_type: 'retail price')
      resource_object.save
    end
  end
end