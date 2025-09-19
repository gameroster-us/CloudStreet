class Tasks::GCP::TerminateEventExecutionWorker

  include Sidekiq::Worker
  sidekiq_options queue: :task_queue, retry: false, backtrace: true

  def perform(options, terminate_id)
    ESLog.info "====Terminate Event Execution Worker========#{options}==========#{terminate_id}==="
    options.symbolize_keys!
    task = Task.find_by(id: options[:task_id])
    return unless task.present?

    terminate_service(options, task, terminate_id) if options[:terminate] == "service"
  rescue => e
    ESLog.error e.message
    ESLog.error e.backtrace
  end

  def terminate_service(options, task, service_id)
    service = GCP::Resource.find_by(id: service_id)
    return unless service.present?

    data = options[:data]
    data.merge!(action_owner_details: task, resource_previous_state: service.state, from: "service")
    if task.is_dry_run == true
      TaskService::Loggers::EventLoggers.set_activity_log(service, {}, data)
    else
      TaskService::Actions::GCP::Terminator.call(service) do |result|
        TaskService::Loggers::EventLoggers.set_activity_log(service, result, data)
      end
    end
  end

end
