class AzureLinkResourcesToTaskWorker

  include Sidekiq::Worker
  sidekiq_options queue: :task_queue, retry: false, backtrace: true

  def perform(task_id)
    task = Task.find_by(id: task_id)
    return unless task.present?

    ESLog.info "--------------inside AzureLinkResourcesToTaskWorker======#{task.title}============="
    task.get_resources_for_task(batch.try(:bid))
  rescue => e
    ESLog.error e.message
    ESLog.error e.backtrace
  end

end
