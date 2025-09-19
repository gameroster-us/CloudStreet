# frozen_string_literal: true

class CSIntegration::Azure::MetricSearcher < CloudStreetService
  def self.search_info(params, &block)
    resource_id = params.keys.first
    # applicable_filters = { adapter_id: params[provider_id][:adapter_id], region_id: params[provider_id][:region_id], provider_id: provider_id }
    resource = Azure::Resource.find_by_id(resource_id)
    metrices = fetch_metrices(resource, params[resource_id])
    status Status, :success, metrices, &block
  rescue Exception => e
    status Status, :error, e, &block
  end

  def self.fetch_metrices(resource, metric_params)
    interval = get_interval(metric_params[:interval]) # incoming interval in minutes formatted to respective Iso-8601
    duration = metric_params[:duration]
    interval_in_second = metric_params[:interval].to_i * 60
    adapter = resource.adapter
    start_time = get_start_time(duration).utc # incoming duration in hours converted into it's actual start date
    end_time = Time.now.utc.iso8601
    monitor_client = adapter.azure_monitor(adapter.subscription_id)
    metrices_hash = { resource.id.to_sym => {} }
    metric_params[:metric_names].each do |metric|
      begin
        CSLogger.info "=================================== Metric: #{metric}"
        metric_result = get_metric(monitor_client, resource, metric, "#{start_time.iso8601}/#{end_time}", interval, 'total,maximum,minimum,average,count')
        metric_result = metric_result.map { |timestamp_metric| { average: get_metric_aggregation_value(timestamp_metric.average), minimum: get_metric_aggregation_value(timestamp_metric.minimum), maximum: get_metric_aggregation_value(timestamp_metric.maximum), total: get_metric_aggregation_value(timestamp_metric.total), count: get_metric_aggregation_value(timestamp_metric.count), time_stamp: Time.at(timestamp_metric.time_stamp).utc } }
      rescue StandardError => e
        CSLogger.error "Error while fetching metric ----- #{e.message}"
        metric_result = if metric.eql?('memory_metric')
                          []
                        else
                          (start_time.to_i..1.second.ago.utc.to_i).step(interval_in_second.seconds).map { |datetime| { average: 0, minimum: 0, maximum: 0, total: 0, count: 0, time_stamp: Time.at(datetime).utc } }
                        end
      end
      metrices_hash[resource.id.to_sym].merge!({ metric.tr('/ ', '') => metric_result }) if metric_result
    end
    metrices_hash
  end

  def self.get_metric(monitor_client, service, metric_name, timespan, interval = 'PT1H', aggregation = 'average')
    args = {
      timespan: timespan,
      interval: interval,
      metricnames: metric_name,
      aggregation: aggregation
    }
    is_memory_metric = service.type.eql?('Azure::Resource::Compute::VirtualMachine') && metric_name.eql?('memory_metric')
    args = update_metric_params(service, args) if is_memory_metric
    if service.type.eql?('Azure::Resource::Compute::Disk') && metric_name.eql?('Disk IOPS consumption percentage')
      service, args = update_metric_params_for_disk(service, args)
    end
    monitor_data = monitor_client.list(service.provider_data['id'], args)
    monitor_data.on_success { |result| return result[0].timeseries[0].data }
    monitor_data.on_error { |_error_code, error_message, _data| raise(StandardError.new, error_message || 'data not found') }
  end

  def self.update_metric_params(vm_instance, args)
    if vm_instance.os_disk['os_type'].eql?('Windows')
      args[:metricnames] = 'Memory\\% Committed Bytes In Use'
      args.merge!(metricnamespace: 'azure.vm.windows.guestmetrics')
    else
      args[:metricnames] = 'mem/used_percent'
      args.merge!(metricnamespace: 'azure.vm.linux.guestmetrics')
    end
  end

  def self.update_metric_params_for_disk(service, args)
    CSLogger.info '======Updating metric name and filter to get disk iops through VM========='
    parent_vm = service.parent_resources.virtual_machines.first
    if parent_vm.os_disk['managed_disk']['id'].downcase.eql?(service.provider_data['id'].downcase)
      args.merge!(metricnames: 'OS Disk IOPS Consumed Percentage')
    else
      data_disk = parent_vm.data_disks.find { |data_disk| data_disk['managed_disk']['id'].eql?(service.provider_data['id']) }
      args.merge!(metricnames: 'Data Disk IOPS Consumed Percentage')
      args.merge!(filter: "LUN eq '#{data_disk['lun']}'")
    end
    [parent_vm, args]
  end

  def self.get_interval(interval_in_minutes)
    interval_in_minutes = interval_in_minutes.to_s
    case interval_in_minutes
    when '5'
      'PT5M'
    when '15'
      'PT15M'
    when '30'
      'PT30M'
    when '60'
      'PT1H'
    when '360'
      'PT6H'
    when '720'
      'PT12H'
    when '1440'
      'P1D'
    when '10080'
      'P1W'
    when '43800'
      'P1M'
    else
      'PT1M' # default interval is one minute
    end
  end

  def self.get_start_time(start_time_in_hr)
    start_time_in_hr = start_time_in_hr.to_s
    case start_time_in_hr
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

  def self.get_metric_aggregation_value(actual_value)
    actual_value || 0
  end
end
