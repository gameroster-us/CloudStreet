# Idle Virtual Machine
class TaskService::Idle::Azure::VirtualMachine

  def self.compute_idle_service(adapter, resource, data)
    ESLog.info "======TaskService::Idle::Azure::VirtualMachine========= #{resource.id}"
    begin
      monitor_client = adapter.azure_monitor(adapter.subscription_id)
      days_old = data['additional_conditions_value']['idle_virtual_machine']['days_old'].to_i
      cpu_utilization_count = data['additional_conditions_value']['idle_virtual_machine']['cpu_utilization'].to_f
      start_time = (Time.now - days_old.days).utc.iso8601
      end_time = Time.now.utc.iso8601
      result = monitor_client.list(resource.provider_data["id"], timespan: "#{start_time}/#{end_time}", interval: 'PT1H', metricnames: 'Percentage Cpu', aggregation: 'Average')
      result.on_success do |monitor_data|
        average_cpu_utilisation = result.data[0].timeseries[0].data.any? { |cpu_util| cpu_util.average > cpu_utilization_count if cpu_util.average }
        return average_cpu_utilisation ?  [] : resource.id
      end
    rescue Adapters::InvalidAdapterError
      ESLog.info 'Invalid adapter credentials or permission for Adapters'
      []
    rescue StandardError => e
      ESLog.error e.message
      ESLog.error "==== Standard error in the compute_idle_service disk for ==== #{resource.id}"
      []
    end  
  end
end
