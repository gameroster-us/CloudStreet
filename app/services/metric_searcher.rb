class MetricSearcher < CloudStreetService


  DIMENSIONS = {
    'AWS/EC2' => 'InstanceId',
    'AWS/RDS' => 'DBInstanceIdentifier',
    'AWS/EBS' => 'VolumeId',
    'AWS/ELB' => 'LoadBalancerName', #AvailabilityZone
    'System/Linux' => 'InstanceId',
    'AWS/S3' => 'BucketName',
    'AWS/ApplicationELB' => 'LoadBalancer',
    'AWS/NetworkELB' => 'LoadBalancer'
  }   

  NAMESPACES = {
    rds: 'AWS/RDS',
    server: 'AWS/EC2',
    volume: 'AWS/EBS',
    load_balancer: 'AWS/ELB',
    network_load_balancer: 'AWS/NetworkELB',
    application_load_balancer: 'AWS/ApplicationELB'
  } 

  STORAGE_METRICS_HASH = { 'StandardStorage' => 'STANDARD', 'IntelligentTieringIAStorage' => 'INTELLIGENT_TIERING', 'ReducedRedundancyStorage' => 'REDUCED_REDUNDANCY', 'OneZoneIAStorage' => 'ONEZONE_IA', 'StandardIAStorage' => 'STANDARD_IA', 'GlacierStorage' => 'GLACIER', 'DeepArchiveStorage' => 'DEEP_ARCHIVE' }


  def self.search(params, &block)
    metric_params = params[:service_params]
    fetched_metric_data = wrapper_agent(params)      
    status Status, :success, fetched_metric_data, &block
    return fetched_metric_data

  end
  
  def self.search_info(params, &block)
    provider_id = params.keys.first
    is_s3 = params.key? 's3'
    if is_s3
      params.delete 's3'
      fetched_metric_data = s3_independent_agent(params)
    else
      service_id = Service.where(provider_id: provider_id, adapter_id: params[provider_id]["adpater_id"], region_id: params[provider_id]["region_id"]).pluck(:id).first
      if service_id.present?
        params[service_id] = params.delete provider_id
        fetched_metric_data = wrapper_agent(params)
      else
        fetched_metric_data = independent_agent(params)
      end
    end
    status Status, :success, fetched_metric_data, &block
    return fetched_metric_data
  end

  def self.independent_agent(params)
    service_metric_hash = {}
    provider_id = params.keys.first
    namespace =  params[provider_id]["metric_names"].include?("VolumeReadOps" || "VolumeWriteOps") ?  "AWS/EBS" : "AWS/RDS"
    metric_params = {
      adapter: Adapter.find(params[provider_id]["adpater_id"]),
      region: Region.find(params[provider_id]["region_id"]),
      metric_names: params[provider_id]["metric_names"],
      start_time: params[provider_id]["start_time"],
      period: params[provider_id]["period"],
      namespace: namespace,
      provider_id: provider_id
    }
    metric_hash = get_matric_data(metric_params)
    service_metric_hash.merge!(provider_id => metric_hash)
    service_metric_hash
  end

  def self.wrapper_agent(params)
    service_ids = params.keys
    service_metric_hash = {}
    service_ids.each do |service_id|
      service = Service.find_by_id(service_id)
      next(service_id) unless service
      metric_params = {
        adapter: service.adapter,
        region: service.region_id.nil? ? service.region : Region.find(service.region_id),
        metric_names: params[service_id][:metric_names],
        start_time: params[service_id][:start_time],
        period: params[service_id][:period],
        namespace: NAMESPACES[service.generic_type.split('::').last.underscore.to_sym],
        provider_id: service.provider_id,
        dimension_value: get_dimension_value(service)
      }
      metric_hash = get_matric_data(metric_params)
      service_metric_hash.merge!(service_id => metric_hash)
    end
    service_metric_hash
  end

  def self.s3_independent_agent(params)
    service_metric_hash = {}
    s3_key = params.keys.first
    namespace = "AWS/S3"
    current_storage = params[s3_key]["current_storage"]
    current_storage_metric = STORAGE_METRICS_HASH.key(current_storage)
    metric_params = {
      adapter: Adapter.find(params[s3_key]["adpater_id"]),
      region: Region.find(params[s3_key]["region_id"]),
      metric_names: params[s3_key]["metric_names"],
      start_time: params[s3_key]["start_time"],
      period: params[s3_key]["period"],
      namespace: namespace,
      provider_id: s3_key,
      storage_metric: current_storage_metric
    }
    metric_hash = get_matric_data(metric_params)
    service_metric_hash.merge!(s3_key => metric_hash)
    service_metric_hash
  end

  def self.get_matric_data(metric_params)
    adapter = metric_params[:adapter]
    region = metric_params[:region]
    metric_names = metric_params[:metric_names]
    start_time =  get_start_time(metric_params[:start_time])
    period = metric_params[:period].to_i*60
    provider_id = metric_params[:dimension_value] || metric_params[:provider_id]
    metric_hash = {}
    metric_names.each do |metric_name|
      if metric_name.eql?('MemoryUtilization')
        namespace = "System/Linux"
      else
        namespace = metric_params[:namespace]
      end
      begin
        # This is done for Ec2 as we are now cosnidering more statictic that why we need sdk instead of fog
        if ["AWS/RDS", "AWS/EC2", "System/Linux"].include? namespace
          cloudwatch_client = adapter.cloudwatch_sdk_client(region.code)
          response = cloudwatch_client.get_metric_statistics(metric_name: metric_name, namespace: namespace, dimensions: [{ name: DIMENSIONS[namespace], value: provider_id }], statistics: %w(Average Sum SampleCount Maximum Minimum), start_time: (start_time).utc, end_time: (1.second.ago).utc, period: period, extended_statistics: ["p95.0"])
          response_datapoints = response.datapoints
        # This is for s3 there is different way of calling but we can optmised here.
        elsif namespace == "AWS/S3"
          response = adapter.connection_cloudwatch_client(region.code).get_metric_statistics("MetricName"=> metric_name, "Namespace"=>namespace, "Dimensions"=>[{"Name"=>DIMENSIONS[namespace], "Value"=>provider_id}, { "Name"=>"StorageType","Value"=> metric_params[:storage_metric] }], "Statistics"=>%w(Average Sum SampleCount Maximum Minimum),"StartTime" => (start_time).iso8601, "EndTime"=> (1.second.ago).iso8601, "Period"=> period)
          response_datapoints = response.body["GetMetricStatisticsResult"]["Datapoints"]
        else
          response = adapter.connection_cloudwatch_client(region.code).get_metric_statistics("MetricName"=> metric_name, "Namespace"=>namespace, "Dimensions"=>[{"Name"=>DIMENSIONS[namespace], "Value"=>provider_id}], "Statistics"=>%w(Average Sum SampleCount Maximum Minimum),"StartTime" => (start_time).iso8601, "EndTime"=> (1.second.ago).iso8601, "Period"=> period)
          response_datapoints = response.body["GetMetricStatisticsResult"]["Datapoints"]
        end
      rescue StandardException => e
        CSLogger.info "Namespace | #{namespace}"
        CSLogger.error "Error while fetching Cloudwatch Message | #{e.message}"
        CSLogger.error "Error while fetching Cloudwatch Bactrace | #{e.bactrace}"
      end
      next(metric_name) unless response
      if response_datapoints.empty?
        parsed_response = (start_time.utc.to_i .. (1.second.ago).utc.to_i).step(period.seconds).map { |datetime| {'average' => 0, 'maximum' => 0, 'minimum' => 0, 'sample_count' => 0, 'sum' => 0, 'p95.0' => 0, 'timestamp' => Time.at(datetime).utc} }
        # When below metric data not coming, we are not showing in UI, that whu sedning false.
        metric_hash.merge!({ memory_utilization: false }) if metric_name.eql?('MemoryUtilization')
      else
        if ["AWS/RDS", "AWS/EC2", "System/Linux"].include? namespace
          parsed_response = response.datapoints.map {|i| {'timestamp' => i.timestamp, 'unit' => i.unit, 'p95.0' => i.extended_statistics['p95.0'],
            'sample_count' => i.sample_count, 'average' => i.average, 'sum' => i.sum, 'minimum' => i.minimum, 'maximum' => i.maximum }}
        else
          parsed_response = response.body["GetMetricStatisticsResult"]["Datapoints"].map{|metric| metric.transform_keys!{|key| key.underscore}}
        end
      end
      metric_hash.merge!({metric_name => parsed_response.sort_by {|time| time["timestamp"]}})
    end
    return metric_hash
  end

  def self.get_start_time(start_time)
    case start_time.to_s
    when '2190'
      3.months.ago
    when '1460'
      2.months.ago
    when '730'
      1.month.ago
    when '72'
      3.days.ago
    when '168'
      1.week.ago
    when '350'
      2.weeks.ago
    when '1'
      1.hour.ago
    when '3'
      3.hours.ago
    when '6'
      6.hours.ago
    when '24'
      24.hours.ago
    else
      5.minutes.ago
    end
  end

  def self.get_dimension_value(service)
    if %w[network_load_balancer application_load_balancer].include?(service.generic_type.split('::').last.underscore)
      service.try(:arn)&.split('/').reverse[0..2].reverse.join('/')
    else
      service.provider_id
    end
  end
end
