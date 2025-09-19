# Idle Load Balancer
class TaskService::Idle::Azure::LoadBalancer
  def self.compute_idle_service(adapter, resource, data)
    ESLog.info "====== TaskService::Idle::Azure::LoadBalancer========= #{resource.id}"
    begin
      # For the basic type of load balancer the metic is not avialable so we are not considering as idle.
      return [] if resource.provider_data.present? && resource.provider_data['sku']['name'].eql?('Basic')

      monitor_client = adapter.azure_monitor(adapter.subscription_id)

      # User Input
      days_old = data['additional_conditions_value']['idle_load_balancer_azure']['days_old'].to_i
      byte_average = data['additional_conditions_value']['idle_load_balancer_azure']['byte_count'].to_f
      start_time = (Time.now - days_old.days).utc.iso8601
      end_time = Time.now.utc.iso8601

      byte_count = get_metric(monitor_client, resource, 'ByteCount', "#{start_time}/#{end_time}")
      byte_count = if byte_count[0].timeseries.blank?
                     false
                   else
                     byte_count[0].timeseries[0].data.any? { |timestamp| bytes_to_megbaytes(timestamp.average) > byte_average unless timestamp.average.blank? }
                   end
      byte_count ? [] : resource.id
    rescue Adapters::InvalidAdapterError
      ESLog.error 'Invalid adapter credentials or permission for Adapters'
      []
    rescue StandardError => e
      ESLog.error e.message
      ESLog.error "==== Standard error in the compute_idle_service load balancer for ==== #{resource.id}"
      []
    end
  end

  def self.get_metric(monitor_client, resource, metric_name, timespan, aggregation = 'average')
    monitor_data = monitor_client.list(resource.provider_data['id'], timespan: timespan, interval: 'PT1H', metricnames: metric_name, aggregation: aggregation)
    monitor_data.on_success { |result| return result }
    monitor_data.on_error { |_error_code, error_message, _data| raise StandardError.new, error_message }
  end

  def self.bytes_to_megbaytes(bytes)
    bytes / (1024.0 * 1024.0)
  end
end
