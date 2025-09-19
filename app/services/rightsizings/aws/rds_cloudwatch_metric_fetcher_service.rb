# frozen_string_literal: true

# Rds CloudwatchMetric Fetcher Service
class Rightsizings::AWS::RdsCloudwatchMetricFetcherService < ApplicationService
  attr_accessor :aws_account, :region_code, :adapter
  SUPPORTED_ENGINE = %w[postgres mysql oracle-ee oracle-se oracle-se1 oracle-se2 sqlserver-ee sqlserver-ex sqlserver-se sqlserver-web]
  RUNNINGSTATE = 'running'
  SERVICE_TYPE = 'Services::Database::Rds::AWS'
  AWS_RDS_METRIC = %w[CPUUtilization FreeableMemory]
  PAST_DAYS = 14
  LICENSE_MODEL = { 'license-included' => 'License included', 'bring-your-own-license' => 'Bring your own license',
                    'general-public-license' => 'No license required', 'postgresql-license' => 'No license required' }

  def initialize(options = {})
    @aws_account = options[:aws_account_id]
    @region_code = options[:region_code]
    @adapter = Adapter.find_by_id(options[:adapter_id])
  end

  def fetch_cloudwatch_metrics
    Sidekiq.logger.info "**** RDS Started Fetching cloudwatch metrics for Region => #{region_code} Account => #{aws_account}"
    begin
      results = []
      get_all_rds_of_region = get_rds(region_code)
      get_all_rds_of_region.each do |rds|
        Sidekiq.logger.info "**** Region => #{region_code} Account => #{aws_account} rds ---> (#{rds.id})"
        results << get_metrics(rds)
      end
      save_data_to_db(results.flatten)
      Sidekiq.logger.info "**** RDS Completed Fetching cloudwatch metrics for Region => #{region_code} Account => #{aws_account} Count => #{get_all_rds_of_region.count}"
    rescue StandardError => e
      Sidekiq.logger.error "**** fetch_cloudwatch_metrics RDS Exception: #{e.message} for Region => #{region_code} Account => #{aws_account}"
    end
  end

  def get_rds(region_code)
    return [] if adapter.nil?

    rds = []
    num_retries = 0
    begin
      database_agent = adapter.connection_rds_client(region_code)
      rds_databases = database_agent.try(:servers)
      rds = rds_databases.nil? ? [] : rds_databases.find_all { |r| r.state == 'available' && SUPPORTED_ENGINE.include?(r.engine) }
      Sidekiq.logger.info "**** Completed get_rds Region => #{region_code} Account => #{aws_account} rds: #{rds.map(&:id)}"
    rescue StandardError => e
      Sidekiq.logger.error "**** get_rds RDS Exception: #{e.message} retry count: #{num_retries} Region => #{region_code} Account => #{aws_account}"
      num_retries += 1
      retry if num_retries <= 2
    end
    rds
  end

  def get_metrics(rds)
    avg_usage = {}
    AWS_RDS_METRIC.each do |metric|
      num_retries = 0
      getting_metrics = true
      while getting_metrics
        begin
          args = create_args(metric, rds.id)
          cloud_watch_agent = ProviderWrappers::AWS.cloudwatch_agent(adapter, region_code)
          json_result = cloud_watch_agent.get_metric_statistics(args)
          getting_metrics = false
        rescue StandardError => e
          num_retries += 1
          Sidekiq.logger.error "Region => #{region_code} Account => #{aws_account} Rds id: #{rds.id} Getting metric #{metric} try #{num_retries} of 3"
          Sidekiq.logger.error "Region => #{region_code} Account => #{aws_account} RDS id: #{rds.id} Exception: #{e.message}"
          getting_metrics = false if num_retries >= 3
        end
      end
      metric_max_usages = fetch_metric_max_usage(json_result || [])
      avg_usage.merge!({ metric => metric_max_usages })
    end
    format_metric_result_for_storing(rds, avg_usage)
  rescue StandardError => e
    Sidekiq.logger.error "*** Something went wrong while fetching RDS get_metrics for Region => #{region_code} Account => #{aws_account} rds #{rds.id}"
    Sidekiq.logger.error e.message
    []
  end

  def create_args(metric, rds_id)
    start_time = (Time.now - PAST_DAYS.days).utc.iso8601
    end_time = Time.now.utc.iso8601
    {
      'Dimensions' => [{ 'Name' => 'DBInstanceIdentifier', 'Value' => rds_id }],
      'MetricName' => metric,
      'Namespace' => 'AWS/RDS',
      'Statistics' => %w[Average],
      'StartTime' => start_time,
      'EndTime' => end_time,
      'Period' => 86400
    }
  end

  def fetch_metric_max_usage(metric_response)
    return nil unless metric_response.body['GetMetricStatisticsResult']['Datapoints'].any?

    metric_response.body['GetMetricStatisticsResult']['Datapoints'].max_by { |dp| dp['Average'] }['Average']
  rescue StandardError => e
    Sidekiq.logger.error "*** Something went wrong while RDS fetch_metric_max_usage for Region => #{region_code} Account => #{aws_account} response #{metric_response.inspect}"
    Sidekiq.logger.error e.message
    nil
  end

  def format_metric_result_for_storing(rds_obj, avg_usage)
    # Fetch Rds List
    # CSLogger.info rds_obj
    # CSLogger.info avg_usage
    options = { instance_type: rds_obj.flavor_id, multi_az: rds_obj.multi_az, location: region_code, engine: rds_obj.engine }
    license = rds_obj.license_model
    license_model = options[:license_model] = LICENSE_MODEL.key?(license) ? LICENSE_MODEL[license] : ''
    rds_details = RdsPriceList.where(options)
    Sidekiq.logger.info "**** In format_metric_result_for_storing Region => #{region_code} Account => #{aws_account} rds => #{rds_obj.id} rds_price_list => #{rds_details.to_a} options => #{options}"
    # CSLogger.info rds_details.inspect
    return {} if rds_details.count != 1 || rds_details.first.cpu.nil? || rds_details.first.memory.nil? || rds_details.first.instance_type_family.nil?

    # Data buiild from the price list
    cpu = rds_details.first.cpu
    ram = rds_details.first.memory
    hour_cost = rds_details.first.price
    instance_type_family = rds_details.first.instance_type_family

    # Calculate pecentage for memory and change the key of hash
    avg_usage['cpu_usage'] = avg_usage.delete 'CPUUtilization'
    avg_usage['ram_usage'] = avg_usage.delete 'FreeableMemory'
    current_free_ram = bytes_to_gigbytes(avg_usage['ram_usage'])
    current_ram_usage = ram - current_free_ram
    current_ram_usage_in_percentage = calculate_percentage(ram, current_ram_usage)
    avg_usage['ram_usage'] = current_ram_usage_in_percentage
    avg_usage['cpu_usage'] = avg_usage['cpu_usage'].floor # convert percentage into integer and taking the least value
    rds_obj_tags = rds_obj.tags.map { |k|  k.first+':'+k.last }.join(' | ')

    # Create hash for metric
    rds_metric_hash = {
                        'name' => rds_obj.db_name,
                        'provider_id' => rds_obj.id,
                        'region_code' => region_code,
                        'engine' => rds_obj.engine,
                        'multi_az' => rds_obj.multi_az,
                        'instance_type' => rds_obj.flavor_id,
                        'metric_data' => avg_usage,
                        'instance_type_family' => instance_type_family,
                        'tags' => rds_obj_tags,
                        'cpu' => cpu,
                        'ram' => ram,
                        'cost_by_hour' => hour_cost,
                        'license_model' => license_model,
                        'aws_account_id' => aws_account
                      }
    Sidekiq.logger.info "**** Region => #{region_code} Account => #{aws_account} rds => #{rds_obj.id} rds_metric_hash => #{rds_metric_hash}"
    rds_metric_hash
  rescue StandardError => e
    Sidekiq.logger.error "*** Something went wrong while RDS format_metric_result_for_storing for Region => #{region_code} Account => #{aws_account} rds_obj #{rds_obj}"
    Sidekiq.logger.error e.message
    {}
  end

  def save_data_to_db(results)
    AWSRdsMetric.collection.insert_many(results) if results.any?
  end

  def bytes_to_gigbytes(bytes)
    bytes / (1024.0 * 1024.0 * 1024.0)
  end

  def calculate_percentage(actual, now)
    ((now / actual) * 100).to_i
  end
end
