# StopEventExecutionWorker
class Tasks::VmWare::StopEventExecutionWorker
  include Sidekiq::Worker
  sidekiq_options queue: :task_queue, retry: false, backtrace: true

  def perform(options, inventory_id)
    CSLogger.info "====VmWare Stop Event Execution Worker========#{options}=====#{inventory_id}========"
    options.symbolize_keys!
    task = Task.find_by(id: options[:task_id])
    return unless task.present?

    inventory = VwInventory.find_by(id: inventory_id)
    return unless inventory.present?

    data = options[:data]
    data.merge!(action_owner_details: task, from: 'vm_ware')

    if task.is_dry_run == true
      TaskService::Loggers::EventLoggers.set_activity_log(inventory, {}, data)
    else
      options = {
        name: 'stop',
        status:  'pending',
        vw_inventory_id: inventory.id,
        task_id: task.id,
        user_activity_id: options[:data]['user_activity_id'],
        run_now: options[:data]['run_now']
      }
      ESLog.info "======#{options}===of inventory====="

      response = VwEvent.init_vw_event(options)
    end
  rescue => e
    ESLog.error e.message
    ESLog.error e.backtrace
  end

end
