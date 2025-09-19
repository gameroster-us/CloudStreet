# Idle Database server
class TaskService::Idle::Azure::DBServer
  def self.compute_idle_service(adapter, resource, data)
    ESLog.info "======TaskService::Idle::Azure::DbServer========= #{resource.id}"
    # SQL server doesnt have mettric so we are considering having idle
    # return [] if resource.type.eql?("Azure::Resource::Database::SQL::Server")

    monitor_client = adapter.azure_monitor(adapter.subscription_id)

    days_old = data['additional_conditions_value']['idle_database_azure']['days_old'].to_i
    user_input_percentage = data['additional_conditions_value']['idle_database_azure']['percentage'].to_f

    start_time = (Time.now - days_old.days).utc.iso8601
    end_time = Time.now.utc.iso8601
    if resource.type.eql?('Azure::Resource::Database::SQL::DB')
      only_sql_db(monitor_client, resource, start_time, end_time, user_input_percentage)
    else
      except_sql_db(monitor_client, resource, start_time, end_time, user_input_percentage)
    end
  rescue Adapters::InvalidAdapterError
    ESLog.info 'Invalid adapter credentials or permission for Adapters'
    []
  rescue StandardError => e
    ESLog.error e.message
    ESLog.error "==== Standard error in the compute_idle_service disk for ==== #{resource.id}"
    []
  end

  def self.except_sql_db(monitor_client, resource, start_time, end_time, user_input_percentage)
    network_in = get_metric(monitor_client, resource, 'network_bytes_ingress', "#{start_time}/#{end_time}", 'total')
    network_out = get_metric(monitor_client, resource, 'network_bytes_egress', "#{start_time}/#{end_time}", 'total')
    io_consumption = get_metric(monitor_client, resource, 'io_consumption_percent', "#{start_time}/#{end_time}")

    # static data comparsion
    network_in = network_in[0].timeseries[0].data.any? { |network_in| bytes_to_megbaytes(network_in.total) > 5 unless network_in.total.blank? }
    network_out = network_out[0].timeseries[0].data.any? { |network_out| bytes_to_megbaytes(network_out.total) > 5 unless network_out.total.blank? }
    
    # User input percentage comparsion
    io_consumption = io_consumption[0].timeseries[0].data.any? { |io_consumption| io_consumption.average > user_input_percentage unless io_consumption.average.blank? }

    !network_out && !network_in && !io_consumption ? resource.id : []
  end

  def self.only_sql_db(monitor_client, resource, start_time, end_time, user_input_percentage)
    if %w[Basic Standard Premium].include?(resource.data['sku']['tier'])
      average_dtu_percentage_metric = get_metric(monitor_client, resource, 'dtu_consumption_percent', "#{start_time}/#{end_time}")
      average_dtu_percentage = average_dtu_percentage_metric[0].timeseries[0].data.any? { |average_dtu_percentage| average_dtu_percentage.average > user_input_percentage unless average_dtu_percentage.average.blank? }

      average_dtu_percentage ? [] : resource.id
    else
      cpu_percentage = get_metric(monitor_client, resource, 'cpu_percent', "#{start_time}/#{end_time}")
      data_io_percentage = get_metric(monitor_client, resource, 'physical_data_read_percent', "#{start_time}/#{end_time}")

      # static data comparsion
      cpu_percentage = cpu_percentage[0].timeseries[0].data.any? { |cpu_percentage| cpu_percentage.average > user_input_percentage unless cpu_percentage.average.blank? }

      # User input percentage comparsion
      data_io_percentage = data_io_percentage[0].timeseries[0].data.any? { |data_io_percentage| data_io_percentage.average > 5 unless data_io_percentage.average.blank? }

      !cpu_percentage && !data_io_percentage ? resource.id : []
    end
  end

  def self.get_metric(monitor_client, resource, metric_name, timespan, aggregation = 'average')
    monitor_data = monitor_client.list(resource.provider_data['id'], timespan: timespan, interval: 'PT1H', metricnames: metric_name, aggregation: aggregation)
    monitor_data.on_success do |result|
      return result
    end
    monitor_data.on_error do |error_code, error_message, data|
      raise StandardError.new, error_message
    end
  end

  def self.bytes_to_megbaytes(bytes)
    bytes / (1024.0 * 1024.0)
  end
end
