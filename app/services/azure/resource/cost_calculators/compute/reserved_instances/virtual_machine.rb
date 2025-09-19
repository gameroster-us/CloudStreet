# frozen_string_literal: false

module Azure::Resource::CostCalculators::Compute::ReservedInstances
  # Service class to calculate
  # and update Azure reserved VM cost
  class VirtualMachine
    RESERVED_TERM_MAP = { 'P1Y' => '1 Year', 'P3Y' => '3 Years' }.freeze
    attr_accessor :adapter, :vm_object, :region_reserved_prices, :reserved_term, :reserved_unit_price

    def initialize(adapter)
      @adapter = adapter
    end

    def start_updating_cost
      regions_vms = Azure::Resource::Compute::VirtualMachine.where(adapter_id: adapter.id, cost_by_hour: 0.0)
                                                            .active
                                                            .reserved_vms
                                                            .exclude_stopped_deallocated
                                                            .group_by(&:region_id)
      regions_vms.each do |region_id, vms|
        begin
          region = Region.find_by(id: region_id)
          next unless region.present?

          @region_reserved_prices = Azure::RetailPriceList.virtual_machine_prices
                                                          .where(region_code: region.code)
                                                          .first
                                                          .reserved_vm_prices
          next unless region_reserved_prices.present?

          vms.each do |vm_obj|
            @vm_object = vm_obj
            update_vm_cost
          end
        rescue StandardError => e
          CSLogger.error e.message
          CSLogger.error e.backtrace
        end
      end
    end

    def update_vm_cost
      update_log
      set_reserved_term!
      set_reserved_unit_price! if reserved_term.present?
      update_cost_by_hour if reserved_unit_price.present?
    rescue StandardError => e
      CSLogger.error e.message
      CSLogger.error "Error : Something went wrong while adding RI cost for VM : #{vm_object.name}"
    end

    def update_log
      CSLogger.info "Updating RI cost for vm : #{vm_object.name} of adapter -- #{adapter.name}"
    end

    def set_reserved_term!
      return unless vm_object.present?

      applicable_filters = {
        subscription_id: adapter.subscription_id,
        location: vm_object.region.code,
        sku_name: vm_object.vm_size
      }
      ri_detail = Azure::RIDetail.where(applicable_filters).first
      @reserved_term = RESERVED_TERM_MAP[ri_detail.try(:term)] || '1 Year'
    end

    def set_reserved_unit_price!
      return unless region_reserved_prices.present?

      reserved_retail_price = region_reserved_prices.find do |reserved_price|
        reserved_price['reservationTerm'].eql?(reserved_term) &&
          (reserved_price['armSkuName'].try(:downcase)).eql?(vm_object.vm_size.try(:downcase))
      end
      @reserved_unit_price = reserved_retail_price['retailPrice'].try(:to_f)
    end

    def update_cost_by_hour
      cost_by_hour = calculate_cost_by_hour
      return unless cost_by_hour.present?

      vm_object.cost_by_hour = cost_by_hour
      vm_object.additional_properties.merge!(price_type: 'retail price')
      vm_object.save
    end

    private

    def calculate_cost_by_hour
      year = @reserved_term.split(' ').first.try(:to_i)
      return unless year.positive?

      reserved_unit_price / (year * 8766) # 8766 is the equivalent hour value of 1 year
    end
  end
end
