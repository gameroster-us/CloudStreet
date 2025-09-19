class Sync::Azure::UsageCostFetcherWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, :retry => false, backtrace: true
  def perform(options)
    begin
      sync_redis_hash_name = "syncAzureAdapter:#{options['adapter_id']}"
      adapter_str = ""
      ::REDIS.with do |conn|
        adapter_str = conn.hget(sync_redis_hash_name, "adapter")
      end
      adapter = Adapter.new JSON.parse(adapter_str)
      start_datetime = Time.parse(Date.today.beginning_of_month.to_s)
      end_datetime = Time.now
      usage_params = {
        "start_datetime" => ProviderWrappers::Azure::Commerce::Usage.format_date_params_for_usage(start_datetime, "Daily"),
        "end_datetime" => ProviderWrappers::Azure::Commerce::Usage.format_date_params_for_usage(end_datetime, "Daily"),
        "api_version" => "2015-06-01-preview",
        "aggregation_granularity" => "Daily"
      }
      usage_cost = Azure::UsageCost.get_aggregate_usage_cost_from_remote(adapter, options["provider_subscription_id"], usage_params)
      usage_params.merge!({
        "usage_cost" => usage_cost,
        "show_details" => true,
        "subscription_id" => options["subscription_id"]
      })
      Azure::UsageCost.create_or_update_usage_cost(usage_params)
    rescue Exception => e 
      CSLogger.error "Sync::Azure::UsageCostFetcherWorker- Error in fetching cost data #{e.class} : #{e.message} : #{e.backtrace}"
    end
  end
end