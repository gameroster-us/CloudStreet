# frozen_string_literal: true

module Rightsizings
  module  Azure
    # service to format and store metric data
    class AzureSQLDBMetricFetcherService < ApplicationService

      include Helper
      attr_accessor :subscription, :adapter, :region

      def initialize(options = {})
        @subscription = options[:subscription]
        @adapter = options[:adapter]
        @region = options[:region]
      end

      def fetch_sql_db_metrics
        CSLogger.info "Started Fetching sql db metrics for subscription : #{subscription} and  Region :#{region}"
        begin
          results = []
          get_all_sql_db(region).each do |db|
            results << get_metrics(db)
          end
          
          ::Azure::Metric.collection.insert_many(results.compact.flatten) if results.any?
          CSLogger.info "Completed Fetching sql db metrics for subscription_id : #{subscription} and  Region :#{region}"
        rescue StandardError => e
          CSLogger.error "Exception: #{e.message} for #{region} and account #{subscription}"
          CSLogger.error e.backtrace
        end
      end

      def get_all_sql_db(region)
        adapters = Adapter.azure_normal_active_adapters.where("data->'subscription_id' =?", subscription)
        account = adapters.first.account
        adapter_ids = adapters.pluck(:id)
        unoptmised_configs = account.service_adviser_configs.azure_unoptimized_sql_default_config.config_details
        get_scope_method_name = get_status_from_config(unoptmised_configs)
        region = Region.find_by_code(region)
        dbs = ::Azure::Resource::Database::SQL::DB
                      .includes(:adapter, :resource_group, :region)
                      .where(adapter_id: adapter_ids, region_id: region&.id)
                      .active
                      .send(get_scope_method_name)
        dbs.uniq { |db| db.provider_data['id'] }
      end

      def get_metrics(db)
        max_usage_arr = []
        azure_metrics = CommonConstants::AZURE_SQL_DB_METRIC_UNIT_MAP.dup
        azure_metrics.keys.each do |metric|
          CSLogger.info "Getting metric data for db #{db.name} metric--#{metric}"
          args = create_args(metric)
          num_retries = 0
          getting_metrics = true
          while getting_metrics
            begin
              cloudwatch = adapter.azure_monitor(adapter.subscription_id)
              json_result = cloudwatch.list(db.provider_data['id'], args)
              getting_metrics = false
            rescue StandardError => e
              num_retries += 1
              CSLogger.info "Getting CW metric #{metric} try  #{num_retries} of 3"
              CSLogger.error "Exception: #{e.message}"
              getting_metrics = false if num_retries >= 3
            end
          end
          metric_max_usages = fetch_metric_max_usage((json_result || []), metric)
          ##return [] if metric_max_usages.nil?
          max_usage_arr << { metric => metric_max_usages, 'unit' => azure_metrics[metric] }
        end
        format_metric_result_for_storing(db, max_usage_arr)
      rescue StandardError => e
        CSLogger.error "Something went wrong while fetching Azure Metric data for db #{db.name} of subscription #{subscription}"
        CSLogger.error e.message
        CSLogger.error e.backtrace
      end

      def create_args(metric)
        start_time = (Time.now - 14.days).utc.iso8601
        end_time = Time.now.utc.iso8601
        {
          timespan: "#{start_time}/#{end_time}",
          interval: 'PT1H',
          metricnames: metric,
          aggregation: 'Maximum'
        }
      end

      def fetch_metric_max_usage(metric_response, metric)
        return if metric_response.blank? || metric_response.data.blank?
        max_arr = metric_response.data[0].timeseries[0].data.map(&:maximum).compact
        max_arr.sum / max_arr.count
      rescue StandardError
        nil
      end

      def format_metric_result_for_storing(db_obj, max_usage_arr)
        {
          'name' => db_obj.name,
          'provider_id' => db_obj.provider_data['id'],
          'subscription_id' => subscription,
          'region_code' => db_obj.region.code,
          'cost_by_hour' => db_obj.cost_by_hour.to_f,
          'metric_data' => max_usage_arr,
          'resource_type' => 'sqldb'
        }
      end
    end
  end
end
