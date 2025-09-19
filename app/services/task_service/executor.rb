# frozen_string_literal: true

# Task Executor
class TaskService::Executor < CloudStreetService
  class << self
    ## code for run now and dry run functinality
    def execute_now(params, &block)
      task = Task.find_by(id: params[:id])
      recommendation_policy = (task.present? && task.event_for.include?('recommendation_service')) ? RecommendationPolicy.exclude_soft_deleted.where(id: task.recommendation_policy_id).exists? : true
      if task.present? && recommendation_policy
        event_batch = Sidekiq::Batch.new
        event_batch.description = 'Run now Event Batch'
        options = { task_id: task.id, run_task_now: true }
        event_batch.on(:complete, EventBatchCallback::EventCallback, options)
        event_batch.on(:success, EventBatchCallback::EventCallback, options)
        event_batch.jobs do
          TaskWorker.perform_in(2.seconds, task.id, true)
        end
        progress_data = { 'total' => 0, 'success' => 0, 'failure' => 0 }
        task.update_columns(progress: progress_data)
        task.update_task_status
        status Status, :success, task, &block
      else
        unless recommendation_policy
         status Status, :error, 'Unable to process this task as the associated recommendation policy is not valid or has been deleted', &block
         return
       end
        status Status, :error, 'Task is not present', &block
      end
    end
  end
end
