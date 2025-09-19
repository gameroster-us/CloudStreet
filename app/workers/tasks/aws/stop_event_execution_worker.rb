class Tasks::AWS::StopEventExecutionWorker

  include Sidekiq::Worker
  sidekiq_options queue: :task_queue, retry: false, backtrace: true

  def perform(options, service_id)
    ESLog.info "====Stop Event Execution Worker========#{options}======#{service_id}======="
    options.symbolize_keys!
    task = Task.find_by(id: options[:task_id])
    return unless task.present?

    service = Service.find_by(id: service_id)
    return unless service.present?

    data = options[:data].symbolize_keys
    data.merge!(action_owner_details: task, resource_previous_state: service.state, from: "service")
    if task.is_dry_run == true
      TaskService::Loggers::EventLoggers.set_activity_log(service, {}, data)
    else
      if service.environment.present?
        ServiceStopper.stop(service, task.created_by) do |result|
          TaskService::Loggers::EventLoggers.set_activity_log(service, result, data)
        end
      else
        Service::AWS::Stopper.call(service) do |result|
          TaskService::Loggers::EventLoggers.set_activity_log(service, result, data)
        end
      end
    end
  rescue => e
    ESLog.error e.message
    ESLog.error e.backtrace
  end

end
