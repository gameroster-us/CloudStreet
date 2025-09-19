# frozen_string_literal: true

# Service to calculate data store cost
module VmWare
  module Resource
    module CostCalculators
      class DataStoreCostService
        def self.add_costing(athena_response, data_stores, options)
          results = data_stores.map do |ds|
            ds_data = athena_response.select{|res| res['resource_provider_id'].eql?(ds.provider_id) }
            result = ds_data.sort_by{|ad| ad['created_at']}
            ds_costing_sum = result.map{|data| data['cost'].to_f }.sum
            no_of_days = fetch_no_of_days(result, options)
            if ds_costing_sum
              #NODE- for getting hourly cost we are dividing by 24 because we are getting day cost from athena
              ds.cost_by_hour =  ((ds_costing_sum / no_of_days) / 24).to_f
              CSLogger.info "Set cost by hour for data store #{ds.provider_id} - #{ds.cost_by_hour}"  
            else
              CSLogger.error "Data store cost not available in athena table"
            end
            ds
          end
          VmWare::Importer.call(results)
          CSLogger.info "costing added successfully for vmware data stores"
        end
        def self.fetch_no_of_days(result, options)
          return 1 if result.count.zero?

          number_of_days = (options[:end_date] - options[:start_date] + 1).to_i
          return number_of_days if result.count == number_of_days

          result_first_day = result.first['created_at'].to_date
          return number_of_days if result_first_day == options[:start_date]

          (Date.today - result_first_day).to_i
        end
      end
    end
  end
end
