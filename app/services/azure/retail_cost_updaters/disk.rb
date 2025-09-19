# frozen_string_literal: false

module Azure
  module RetailCostUpdaters
    # Service class to add retail cost
    # For disk missing cost_by_hour
    class Disk < Azure::RetailCostUpdater
      PRODUCT_NAME_MAP = {
        'Standard_LRS' => 'Standard HDD Managed Disks',
        'StandardSSD_LRS' => 'Standard SSD Managed Disks',
        'Premium_LRS' => 'Premium SSD Managed Disks',
        'StandardSSD_ZRS' => 'Standard SSD Managed Disks',
        'Premium_ZRS' => 'Premium SSD Managed Disks',
        'UltraSSD_LRS' => 'Ultra Disks'
      }.freeze

      UNIT_OF_MEASURE = '1/Month'.freeze

      DISK_SIZES = [
        4, 8, 16, 32, 64, 128, 256, 512, 1_024, 2_048, 4_096, 8_192, 16_384, 32_767, 32_768, 65_536
      ].freeze
      # Tier MAP { tier => size_in_GiB }
      STANDARD_HDD_TIER_MAP = {
        'S4' => 32, 'S6' => 64, 'S10' => 128, 'S15' => 256, 'S20' => 512, 'S30' => 1_024,
        'S40' => 2_048, 'S50' => 4_096, 'S60' => 8_192, 'S70' => 16_384, 'S80' => 32_767
      }.freeze

      STANDARD_SSD_TIER_MAP = {
        'E1' => 4, 'E2' => 8, 'E3' => 16, 'E4' => 32, 'E6' => 64,
        'E10' => 128, 'E15' => 256, 'E20' => 512, 'E30' => 1_024,
        'E40' => 2_048, 'E50' => 4_096, 'E60' => 8_192, 'E70' => 16_384, 'E80' => 32_767
      }.freeze

      PREMIUM_SSD_TIER_MAP = {
        'P1' => 4, 'P2' => 8, 'P3' => 16, 'P4' => 32, 'P6' => 64,
        'P10' => 128, 'P15' => 256, 'P20' => 512, 'P30' => 1_024,
        'P40' => 2_048, 'P50' => 4_096, 'P60' => 8_192, 'P70' => 16_384, 'P80' => 32_767
      }.freeze

      def set_region_retail_prices!
        @region_retail_prices = Azure::RetailPriceList.where(region_code: @region.code)
                                                      .storage_prices
                                                      .first&.prices
      end

      def pre_conditions_passed?
        !resource_object.cost_by_hour&.positive?
      end

      class << self
        def get_filter_options(disk_object)
          redundancy = disk_object.sku['name'].split('_').try(:last).try(:upcase)
          product_name = PRODUCT_NAME_MAP[disk_object.sku['name']]
          tier = find_tier(disk_object.sku['name'], disk_object.disk_size_gb)
          { product_name: product_name, sku_name: "#{tier} #{redundancy}", meter_name: "#{tier} Disks" }
        end

        def find_tier(sku, disk_size)
          match_sku_tier(sku, disk_size) || match_sku_tier(sku, find_nearest_size(disk_size))
        end

        # This method only works with sorted(ASC) array of numbers
        # Used Binary search to find the nearest higher disk size
        def find_nearest_size(disk_size)
          min = 0
          max = DISK_SIZES.size - 1
          return DISK_SIZES[0] if disk_size <= DISK_SIZES[0]

          return DISK_SIZES[-1] if disk_size >= DISK_SIZES[max]

          while min < max
            mid = ((min + max) / 2).to_i
            return disk_size if DISK_SIZES[mid].eql?(disk_size)

            if DISK_SIZES[mid] > disk_size
              return DISK_SIZES[mid] if DISK_SIZES[mid - 1] < disk_size

              max = mid - 1
            else
              return DISK_SIZES[mid + 1] if DISK_SIZES[mid + 1] >= disk_size

              min = mid + 1
            end
          end
        end

        def match_sku_tier(sku, disk_size)
          case sku
          when 'Standard_LRS'
            STANDARD_HDD_TIER_MAP.key(disk_size)
          when 'StandardSSD_LRS', 'StandardSSD_ZRS'
            STANDARD_SSD_TIER_MAP.key(disk_size)
          when 'Premium_LRS', 'Premium_ZRS'
            PREMIUM_SSD_TIER_MAP.key(disk_size)
          end
        end
      end

      private

      def set_sku_retail_price!
        if resource_object.ultra_disk?
          set_ultra_disk_prices
        else
          filter_options = self.class.get_filter_options(resource_object)
          sku_retail_price = region_retail_prices.find do |retail_price|
            retail_price['productName'].eql?(filter_options[:product_name]) &&
              retail_price['skuName'].eql?(filter_options[:sku_name]) &&
              retail_price['meterName'].eql?(filter_options[:meter_name]) &&
              retail_price['unitOfMeasure'].eql?(UNIT_OF_MEASURE)
          end
          @sku_retail_price = sku_retail_price || {}
        end
      end

      def set_ultra_disk_prices
        sku_retail_prices = region_retail_prices.select do |retail_price|
          retail_price['productName'].eql?('Ultra Disks') &&
            ['Provisioned IOPS', 'Provisioned Capacity', 'Provisioned Throughput (MBps)'].include?(retail_price['meterName'])
        end
        @sku_retail_price = sku_retail_prices&.pluck('meterName', 'retailPrice').try(:to_h) || {}
      end

      def set_cost_by_hour!
        @cost_by_hour = if resource_object.ultra_disk?
                          calculate_ultra_disk_cost
                        else
                          sku_retail_price['retailPrice'] / (30 * 24)
                        end
      end

      def calculate_ultra_disk_cost
        iops_cost = (resource_object.disk_iopsread_write || 0.0) * (sku_retail_price['Provisioned IOPS'] || 0.0)
        throughput_cost = (resource_object.disk_mbps_read_write || 0.0) * (sku_retail_price['Provisioned Throughput (MBps)'] || 0.0)
        capacity_cost = (self.class.find_nearest_size(resource_object.disk_size_gb) || 0.0) * (sku_retail_price['Provisioned Capacity'] || 0.0)
        (iops_cost || 0.0) + (throughput_cost || 0.0) + (capacity_cost || 0.0)
      end
    end
  end
end
