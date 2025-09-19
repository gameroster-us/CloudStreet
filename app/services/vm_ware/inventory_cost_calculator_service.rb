# frozen_string_literal: true

# Service to calculate cost
module VmWare
  class InventoryCostCalculatorService
    attr_reader :vcenter

    def initialize(vcenter)
      @vcenter = vcenter
    end

  	def add_costing
      start_date = Date.parse(30.days.ago.to_s).strftime('%Y-%m-%d')
      end_date = Date.parse((DateTime.now - 1.day).to_s).strftime('%Y-%m-%d')
      begin 
        CSLogger.info "Getting costing information from Athena......."
        query_string = "SELECT created_at, adapter_id, vcenter_id, vcenter_name, resource_id, resource_type,resource_provider_id, parent_id, uptime_hours, cost FROM #{vcenter.adapter.athena_cost_report_table} where CAST(created_at AS DATE) >= CAST('#{start_date}' AS DATE) AND CAST(created_at AS DATE) <= CAST('#{end_date}' AS DATE) GROUP BY created_at, adapter_id, vcenter_id, vcenter_name, resource_id, resource_type, resource_provider_id, parent_id, uptime_hours, cost"
        athena_response = Athena::QueryService.exec(query_string) do |query_status, query_resp|
          query_status ? parse_athena_response(query_resp) : []
        end
        CSLogger.info "costing information fething done"
       
        if athena_response.present?
          athena_response = athena_response.map{|record_arr| record_arr.inject(:merge)}
          vms = vcenter.vw_inventories.running_vms
          data_stores = vcenter.vw_inventories.data_stores
          options ={
            start_date: start_date.to_date,
            end_date: end_date.to_date
          }
          #Adding cost by hour for vms
          VmWare::Resource::CostCalculators::VirtualMachineCostService.add_costing(athena_response, vms, options) if vms
          #Addign cost by hours for data stores
          VmWare::Resource::CostCalculators::DataStoreCostService.add_costing(athena_response, data_stores, options) if data_stores
        else
          CSLogger.info "Costing information not Available for vcenter #{vcenter.name}"
        end
      rescue Exception => error
        CSLogger.error "#{error.message}"
      end
    end

    def parse_athena_response(query_resp)
      result = query_resp.map { |response| response.try(:data) }.compact.to_json
      result = JSON.parse(result)
      result_headers = result[0].map(&:values).flatten
      result = result.drop(1)
      result.each do |res|
        res.each_with_index do |r, i|
          r.transform_keys! { |key| key = result_headers[i] }
        end
      end
    end
  end
end