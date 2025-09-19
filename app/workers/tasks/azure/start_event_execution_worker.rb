class Tasks::Azure::StartEventExecutionWorker

  include Sidekiq::Worker
  sidekiq_options queue: :task_queue, retry: false, backtrace: true

  def perform(options, resource_id)
    ESLog.info "====AZURE Start Event Execution Worker========#{options}=====#{resource_id}========"
    options.symbolize_keys!
    task = Task.find_by(id: options[:task_id])
    return unless task.present?

    resource = ::Azure::Resource.find_by(id: resource_id)
    return unless resource.present?

    data = options[:data].symbolize_keys
    data.merge!(action_owner_details: task, resource_previous_state: resource.state, from: "resource")

    TaskService::Actions::Azure::Starter.call(resource) do |result|
      TaskService::Loggers::EventLoggers.set_activity_log(resource, result, data)
    end
  rescue => e
    ESLog.error e.message
    ESLog.error e.backtrace
  end

end
