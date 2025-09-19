class RecommendationPolicyManualWorker
  include Sidekiq::Worker

  sidekiq_options queue: :task_queue, retry: false, backtrace: true

  def perform(task_id, activity_id, batch_id = nil, options)
    begin
      task = Task.find_by(id: task_id)
      policy = RecommendationPolicy.find_by(id: task.recommendation_policy_id)
      policy.process_manual_task(task, activity_id, batch_id, options)
    rescue StandardError => e
      CSLogger.error(e.message)
      CSLogger.error(e.backtrace)
    end
  end
    
end
