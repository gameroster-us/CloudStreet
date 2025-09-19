class Azure::CostFetcherAndStorerWorker
  include Sidekiq::Worker
  sidekiq_options queue: :azure_sync, backtrace: true

  def perform(options)
   dump_cost_and_rate(options)
  rescue StandardError => e
    CSLogger.error e.message
    CSLogger.error e.backtrace
  end

  def dump_cost_and_rate(options)
    adapter = Adapters::Azure.find_by(id: options["adapter_id"])    
    unless (adapter.azure_cloud.eql?("AzureChinaCloud") || adapter.csp_adapter? || adapter.ea_adapter?)
      # here we are getting storage account cost from athena for all adapter where we are not taking adapter cost from athena
      dump_storage_account_data(adapter)

      subscription = adapter&.subscription
      usage_costs = subscription&.usage_cost.try(:aggregate_usage_cost) if subscription.present?
      rate_card = Azure::RateCard.find_by(subscription_id: adapter.subscription_id).rates["Meters"] rescue []
      
      categories_rate_card = rate_card.group_by do |rc|
        options['category_map'].fetch(rc['MeterCategory'], 'general')
      end
      # Temporary store Rate Card data to Mongo table
      # for each region and category combination one record will be created
      if Azure::AzureResourceRateCard.where(subscription_id: adapter.subscription_id).count == 0
        categories_rate_card.each do |category, rc|
          begin
            results = []
            rc.group_by{ |data| data['MeterRegion'] }.each do |region, rc_data|
              results << { region_code: region, category: category, subscription_id: adapter.subscription_id, rates: rc_data.to_s }
            end
            CSLogger.info "Inserting #{category} records to monodb"
            Azure::AzureResourceRateCard.collection.insert_many(results) if results.any?
          rescue StandardError => e
            CSLogger.error e.message
            p e
            next
          end
        end
      end
    end

    usage_cost_records = []
    # Temporary store Usage cost to mongo table
    # for each usage cost one record will be created
    if adapter.azure_cloud.eql?("AzureChinaCloud") || adapter.csp_adapter? || adapter.ea_adapter?
      usage_cost_records = get_athena_response(nil, adapter)
    else
      if usage_costs.present?
        usage_cost_records = usage_costs.map do |usage_cost|
          instance_data = (JSON.parse(usage_cost["instance_data"]) || {})
          resource_uri = instance_data['Microsoft.Resources'].try(:[], 'resourceUri')
          next unless resource_uri.present?

          # Get the resource uri in proper format for AKS
          resource_uri_downcase = get_resource_uri(usage_cost, resource_uri)

          {
            subscription_id: adapter.subscription_id,
            resource_uri: resource_uri_downcase,
            usage_costs: usage_cost
          }
        end
      end
    end
    CSLogger.info "Importing data to Temporary table, Please wait ...."
    dump_cost_in_temp_table(usage_cost_records.compact)
    usage_cost_records = []
  end

  def dump_storage_account_data(adapter)
    # store storage account data from athena for all adapter
    usage_storage_cost_records = get_athena_response('Storage', adapter)
    dump_cost_in_temp_table(usage_storage_cost_records.compact, 'Storage')
    CSLogger.info "Stored storage account usages from athena for adapter #{adapter.name}"
    usage_storage_cost_records = []
  end

  def get_athena_response(meter_category='', adapter)
    CSLogger.info "Getting costing from athena, Please wait ........."
    usage_records = []
    billing_adapter = adapter.billing_adapter
    if billing_adapter.present?
      account = billing_adapter.account
      table_name = account.organisation_identifier.try(:downcase) + billing_adapter.get_table_postfix + '_az'
      start_date = Date.parse(30.days.ago.to_s).strftime('%Y-%m-%d')
      end_date = Date.parse((DateTime.now - 1.day).to_s).strftime('%Y-%m-%d')

      if meter_category.eql?('Storage')
        CSLogger.info "getting storage account data"
        query_string = "SELECT resource_name, service_name, service_tier, meter_id, instance_id, pre_tax_cost, resource_rate, meter_category, usage_date_time, usage_quantity as quantity, unit_of_measure as unit FROM #{ATHENA_DATABASE}.#{table_name} where subscription_guid = '#{adapter.subscription_id}' and service_tier IN (#{Azure::Resource::StorageAccount::STORAGE_TYPES.map{|tier| "'#{tier}'"}.join(', ')}) and meter_category = '#{meter_category}' and CAST(usage_date_time AS DATE) >= CAST('#{start_date}' AS DATE) AND CAST(usage_date_time AS DATE) <= CAST('#{end_date}' AS DATE) GROUP BY resource_name, service_name, service_tier, meter_id, instance_id, pre_tax_cost, resource_rate, meter_category, usage_date_time, usage_quantity, unit_of_measure;"
      else
        # Will add new meter_category as 'Functions' for App Service Plan, because for other Tier(Dynamic, Elastic Premium, WorkflowStandard etc) data plan data is comming within.
        query_string = "SELECT resource_name, service_name, service_tier, meter_id, instance_id, pre_tax_cost, resource_rate, meter_category, usage_date_time, usage_quantity as quantity, unit_of_measure as unit, meter_name FROM #{ATHENA_DATABASE}.#{table_name} where subscription_guid = '#{adapter.subscription_id}' and meter_category IN (#{Azure::Resource::EA_ADAPTER_ATHENA_CATEGORY_LIST.map{|category| "'#{category}'"}.join(', ')}) and CAST(usage_date_time AS DATE) >= CAST('#{start_date}' AS DATE) AND CAST(usage_date_time AS DATE) <= CAST('#{end_date}' AS DATE) GROUP BY resource_name, service_name, service_tier, meter_id, instance_id, pre_tax_cost, resource_rate, meter_category, usage_date_time, usage_quantity, unit_of_measure, meter_name;"
      end
      
      Athena::QueryService.exec(query_string) do |query_status, query_resp|
        if query_status
          query_resp = parse_athena_response(query_resp)
          # status ResponseStatus, :success, { report: response }, &block
          usage_records = query_resp.map do |res|
            next unless res['instance_id'].present?

            # Get the resource uri in proper format for AKS
            resource_uri_downcase = get_resource_uri(res, res['instance_id'])
            {
              subscription_id: adapter.subscription_id,
              resource_uri: resource_uri_downcase,
              usage_costs: res,
              resource_type: meter_category,
              currency: billing_adapter.data['currency']
            }
          end
        else
          {}
        end
      end
    end
    usage_records
  end

  # As resource uri comming different in the usage cost with respect to azure resource url
  def get_resource_uri(usage_cost, resource_uri)
    if (usage_cost['meter_category'] == 'Azure Kubernetes Service') && (usage_cost['meter_name'] == 'Uptime SLA')
      resource_uri_downcase = resource_uri.downcase.gsub('containerservices', 'managedclusters')
    else
      resource_uri_downcase = resource_uri.downcase
    end
    resource_uri_downcase
  end

  # def parse_athena_response(query_resp)
  #   result = query_resp.map { |response| response.try(:data) }.compact.to_json
  #   result = JSON.parse(result)
  #   result_headers = result[0].map(&:values).flatten
  #   result = result.drop(1)
  #   result.each do |res|
  #     res.each_with_index do |r, i|
  #       r.transform_keys! { |key| key = result_headers[i] }
  #     end
  #   end
  #   result.map{|r| r.inject(:merge)}
  # end

  def parse_athena_response(query_resp)
    formatted_result = []
    counter = 0
    total_count = query_resp.count
    result_headers = query_resp.first.data.try(:as_json)&.map(&:values)&.flatten || []
    query_resp.each_slice(20000) do |sliced_response|
      result = sliced_response.map { |response| response.try(:data).try(:as_json) }.compact
      result = result.drop(1)
      result = result.map do |res|
        res.each_with_index do |r, i|
          r.transform_keys! { |key| key = result_headers[i] }
        end
        res.inject(&:merge)
      end
      # formatted_result.concat(result.map{|r| r.inject(:merge)})
      formatted_result.concat(result)
      counter += sliced_response.count
      CSLogger.info "Athena cost data parsing done for -- #{counter} of #{total_count}"
    end
    formatted_result
  end

  def dump_cost_in_temp_table(usage_costs, category=nil)
    return unless usage_costs.present?
    category ||= 'all'
    CSLogger.info "===== Started inserting cost for type -> #{category} ===== "
    counter = 0
    total_count = usage_costs.count
    usage_costs.compact.each_slice(50000) do |records|
      counter += records.count
      CSLogger.info "===== Inserting athena cost into temporary table -- Done #{counter} of #{total_count}"
      Azure::SyncTempUsageCost.collection.insert_many(records)
    end
  rescue Exception => e
    CSLogger.error("@@@@@@ ERROR : While dumping cost to temp table during adapter sync @@@@@@@")
    CSLogger.error e.message
    CSLogger.error e.backtrace.first
  end
end
